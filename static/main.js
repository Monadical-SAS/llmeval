/**
 * LLMEval Static Website - Client-side Interactivity
 * Provides filtering, sorting, and search functionality
 */

(function () {
  'use strict';

  // ===== State Management =====
  const state = {
    currentSort: {
      column: null,
      direction: null, // 'asc' or 'desc'
    },
    filters: {
      model: '',
      task: '',
      dateStart: '',
      dateEnd: '',
      search: '',
    },
  };

  // ===== URL Parameter Handling =====
  function getFiltersFromURL() {
    const params = new URLSearchParams(window.location.search);
    return {
      model: params.get('model') || '',
      task: params.get('task') || '',
      dateStart: params.get('dateStart') || '',
      dateEnd: params.get('dateEnd') || '',
      search: params.get('search') || '',
    };
  }

  function saveFiltersToURL() {
    const params = new URLSearchParams();

    // Only add non-empty filter values to URL
    if (state.filters.model) params.set('model', state.filters.model);
    if (state.filters.task) params.set('task', state.filters.task);
    if (state.filters.dateStart) params.set('dateStart', state.filters.dateStart);
    if (state.filters.dateEnd) params.set('dateEnd', state.filters.dateEnd);
    if (state.filters.search) params.set('search', state.filters.search);

    // Update URL without reloading page
    const newURL = params.toString()
      ? `${window.location.pathname}?${params.toString()}`
      : window.location.pathname;

    window.history.pushState({}, '', newURL);
  }

  function restoreFiltersFromURL() {
    const urlFilters = getFiltersFromURL();

    // Update state
    state.filters = urlFilters;

    // Update form elements
    const modelFilter = document.getElementById('filter-model');
    const taskFilter = document.getElementById('filter-task');
    const dateStartFilter = document.getElementById('filter-date-start');
    const dateEndFilter = document.getElementById('filter-date-end');
    const searchFilter = document.getElementById('search-input');

    if (modelFilter && urlFilters.model) modelFilter.value = urlFilters.model;
    if (taskFilter && urlFilters.task) taskFilter.value = urlFilters.task;
    if (dateStartFilter && urlFilters.dateStart) dateStartFilter.value = urlFilters.dateStart;
    if (dateEndFilter && urlFilters.dateEnd) dateEndFilter.value = urlFilters.dateEnd;
    if (searchFilter && urlFilters.search) searchFilter.value = urlFilters.search;

    // Apply filters if any were restored
    if (urlFilters.model || urlFilters.task || urlFilters.dateStart || urlFilters.dateEnd || urlFilters.search) {
      applyFilters();
    }
  }

  // ===== Link Parameter Preservation =====
  function preserveFiltersInLinks() {
    // Add filter parameters to navigation links when clicked
    const links = document.querySelectorAll('a[href*="index.html"], a.date-link, a.breadcrumb-link, a.logo-link');

    links.forEach(function (link) {
      link.addEventListener('click', function (e) {
        // Only process internal navigation links (not external, not file downloads)
        const href = this.getAttribute('href');
        if (!href || href.startsWith('#') || href.startsWith('http') ||
            href.endsWith('.txt') || href.endsWith('.sh') || href.endsWith('.md')) {
          return;
        }

        // Check if there are active filters
        const hasFilters = state.filters.model || state.filters.task ||
                          state.filters.dateStart || state.filters.dateEnd ||
                          state.filters.search;

        if (hasFilters) {
          e.preventDefault();

          // Build URL with preserved filters
          const params = new URLSearchParams();
          if (state.filters.model) params.set('model', state.filters.model);
          if (state.filters.task) params.set('task', state.filters.task);
          if (state.filters.dateStart) params.set('dateStart', state.filters.dateStart);
          if (state.filters.dateEnd) params.set('dateEnd', state.filters.dateEnd);
          if (state.filters.search) params.set('search', state.filters.search);

          // Navigate with filters
          const newURL = params.toString() ? `${href}?${params.toString()}` : href;
          window.location.href = newURL;
        }
      });
    });
  }

  // ===== Initialization =====
  document.addEventListener('DOMContentLoaded', function () {
    initializeFilters();
    initializeSorting();
    initializeSearch();
    initializeModelTags();
    restoreFiltersFromURL();
    preserveFiltersInLinks();
  });

  // ===== Filter Functions =====
  function initializeFilters() {
    // Get filter elements
    const modelFilter = document.getElementById('filter-model');
    const taskFilter = document.getElementById('filter-task');
    const dateStartFilter = document.getElementById('filter-date-start');
    const dateEndFilter = document.getElementById('filter-date-end');
    const clearButton = document.getElementById('clear-filters');

    // Add event listeners
    if (modelFilter) {
      modelFilter.addEventListener('input', function () {
        state.filters.model = this.value.toLowerCase();
        saveFiltersToURL();
        applyFilters();
      });
    }

    if (taskFilter) {
      taskFilter.addEventListener('change', function () {
        state.filters.task = this.value.toLowerCase();
        saveFiltersToURL();
        applyFilters();
      });
    }

    if (dateStartFilter) {
      dateStartFilter.addEventListener('change', function () {
        state.filters.dateStart = this.value;
        saveFiltersToURL();
        applyFilters();
      });
    }

    if (dateEndFilter) {
      dateEndFilter.addEventListener('change', function () {
        state.filters.dateEnd = this.value;
        saveFiltersToURL();
        applyFilters();
      });
    }

    if (clearButton) {
      clearButton.addEventListener('click', function () {
        clearFilters();
      });
    }
  }

  function applyFilters() {
    const table = document.querySelector('table tbody');
    if (!table) return;

    const rows = table.querySelectorAll('tr');
    let visibleCount = 0;

    rows.forEach(function (row) {
      if (shouldShowRow(row)) {
        row.classList.remove('hidden');
        visibleCount++;
      } else {
        row.classList.add('hidden');
      }
    });

    // Update empty state
    updateEmptyState(visibleCount);
  }

  function shouldShowRow(row) {
    // Get row data
    const cells = row.querySelectorAll('td');
    if (cells.length === 0) return false;

    // Get model names - check both row attribute and model tags
    const rowModelAttr = row.getAttribute('data-model-full') || '';
    const modelTags = row.querySelectorAll('.model-tag');
    const allModels = rowModelAttr
      ? rowModelAttr.toLowerCase()
      : Array.from(modelTags).map(tag => tag.getAttribute('data-model-full') || '').join(' ').toLowerCase();

    const rowText = row.textContent.toLowerCase();

    // Apply model filter - search in full model names
    if (state.filters.model) {
      const filterLower = state.filters.model.toLowerCase();
      if (!allModels.includes(filterLower)) {
        return false;
      }

      // Filter model tags in the Models Score column (cell index 1) if present
      const modelsScoreCell = cells[1]; // Models Score column
      if (modelsScoreCell && modelTags.length > 0) {
        filterModelTags(modelsScoreCell, filterLower);
      }
    } else {
      // Reset model tag visibility if no filter
      const modelsScoreCell = cells[1];
      if (modelsScoreCell && modelTags.length > 0) {
        resetModelTags(modelsScoreCell);
      }
    }

    // Apply task filter (if it exists in select)
    if (state.filters.task && !rowText.includes(state.filters.task)) {
      return false;
    }

    // Apply search filter
    if (state.filters.search && !rowText.includes(state.filters.search)) {
      return false;
    }

    return true;
  }

  function filterModelTags(cell, filterModel) {
    const modelTags = cell.querySelectorAll('.model-tag');
    modelTags.forEach(function(tag) {
      const fullModel = (tag.getAttribute('data-model-full') || '').toLowerCase();
      if (fullModel && fullModel.includes(filterModel)) {
        tag.style.display = '';
      } else if (!tag.textContent.includes('+')) {
        // Don't hide the "+X more" tags
        tag.style.display = 'none';
      }
    });
  }

  function resetModelTags(cell) {
    const modelTags = cell.querySelectorAll('.model-tag');
    modelTags.forEach(function(tag) {
      tag.style.display = '';
    });
  }

  function extractDate(dateText) {
    // Try to extract a date in YYYY-MM-DD format from the text
    const match = dateText.match(/(\d{4})-(\d{2})-(\d{2})/);
    if (match) {
      return match[0];
    }
    // Alternative: try to parse the date directly
    const date = new Date(dateText);
    if (!isNaN(date.getTime())) {
      return date.toISOString().split('T')[0];
    }
    return null;
  }

  function clearFilters() {
    // Reset state
    state.filters = {
      model: '',
      task: '',
      dateStart: '',
      dateEnd: '',
      search: '',
    };

    // Reset form elements
    const modelFilter = document.getElementById('filter-model');
    const taskFilter = document.getElementById('filter-task');
    const dateStartFilter = document.getElementById('filter-date-start');
    const dateEndFilter = document.getElementById('filter-date-end');
    const searchFilter = document.getElementById('search-input');

    if (modelFilter) modelFilter.value = '';
    if (taskFilter) taskFilter.value = '';
    if (dateStartFilter) dateStartFilter.value = '';
    if (dateEndFilter) dateEndFilter.value = '';
    if (searchFilter) searchFilter.value = '';

    // Clear URL parameters
    saveFiltersToURL();

    // Show all rows
    applyFilters();
  }

  function updateEmptyState(visibleCount) {
    const table = document.querySelector('table');
    if (!table) return;

    let emptyState = document.querySelector('.empty-state');

    if (visibleCount === 0) {
      if (!emptyState) {
        emptyState = document.createElement('div');
        emptyState.className = 'empty-state';
        emptyState.innerHTML = '<h3>No results found</h3><p>Try adjusting your filters or search terms.</p>';
        table.parentNode.insertBefore(emptyState, table.nextSibling);
      }
      table.style.display = 'none';
    } else {
      if (emptyState) {
        emptyState.remove();
      }
      table.style.display = '';
    }
  }

  // ===== Sorting Functions =====
  function initializeSorting() {
    const sortableHeaders = document.querySelectorAll('th.sortable');

    sortableHeaders.forEach(function (header, index) {
      header.addEventListener('click', function () {
        sortTable(index, header);
      });
    });
  }

  function sortTable(columnIndex, headerElement) {
    const table = document.querySelector('table');
    if (!table) return;

    const tbody = table.querySelector('tbody');
    const rows = Array.from(tbody.querySelectorAll('tr'));

    // Determine sort direction
    let direction = 'asc';
    if (state.currentSort.column === columnIndex) {
      direction = state.currentSort.direction === 'asc' ? 'desc' : 'asc';
    }

    // Update state
    state.currentSort.column = columnIndex;
    state.currentSort.direction = direction;

    // Update header classes
    const allHeaders = table.querySelectorAll('th.sortable');
    allHeaders.forEach(function (header) {
      header.classList.remove('sort-asc', 'sort-desc');
    });
    headerElement.classList.add(direction === 'asc' ? 'sort-asc' : 'sort-desc');

    // Sort rows
    rows.sort(function (rowA, rowB) {
      const cellA = rowA.querySelectorAll('td')[columnIndex];
      const cellB = rowB.querySelectorAll('td')[columnIndex];

      if (!cellA || !cellB) return 0;

      const valueA = getCellValue(cellA);
      const valueB = getCellValue(cellB);

      // Compare values
      let comparison = 0;
      if (typeof valueA === 'number' && typeof valueB === 'number') {
        comparison = valueA - valueB;
      } else {
        comparison = String(valueA).localeCompare(String(valueB));
      }

      // If primary comparison is equal, use duration as tiebreaker (ascending - faster is better)
      if (comparison === 0) {
        const durationA = getDurationValue(rowA);
        const durationB = getDurationValue(rowB);
        if (durationA !== null && durationB !== null) {
          comparison = durationA - durationB; // Always ascending for duration
        }
      }

      return direction === 'asc' ? comparison : -comparison;
    });

    // Re-append rows in sorted order
    rows.forEach(function (row) {
      tbody.appendChild(row);
    });
  }

  function getCellValue(cell) {
    // Check for data-sort attribute FIRST (for dates and other special values)
    const sortValue = cell.getAttribute('data-sort');
    if (sortValue) {
      // Try to parse as number
      const sortNum = parseFloat(sortValue);
      if (!isNaN(sortNum)) return sortNum;
      // For ISO date strings, parse as timestamp
      const sortDate = new Date(sortValue);
      if (!isNaN(sortDate.getTime())) {
        return sortDate.getTime();
      }
      return sortValue;
    }

    // Try to extract numeric value
    const text = cell.textContent.trim();

    // Check for test result emojis (✅ = pass = 1, ❌ = fail = 0, — = missing = -1)
    if (text === '✅') return 1;
    if (text === '❌') return 0;
    if (text === '—') return -1;

    // Check for percentage
    if (text.includes('%')) {
      const num = parseFloat(text.replace('%', ''));
      if (!isNaN(num)) return num;
    }

    // Check for plain number
    const num = parseFloat(text);
    if (!isNaN(num)) return num;

    // Check for date
    const date = new Date(text);
    if (!isNaN(date.getTime())) {
      return date.getTime();
    }

    // Return text as-is
    return text.toLowerCase();
  }

  function getDurationValue(row) {
    // For run page, duration is in column 3 (0-indexed: Score=0, Model=1, Duration=2, SessionKB=3)
    // For root page, duration is not present
    const cells = row.querySelectorAll('td');

    // Check if this is a run page (has Duration column in position 2)
    if (cells.length >= 3) {
      const durationCell = cells[2]; // 3rd column (0-indexed)
      const text = durationCell.textContent.trim();

      // Parse duration format like "2m 15s" or "45s"
      let totalSeconds = 0;

      // Match minutes
      const minutesMatch = text.match(/(\d+)m/);
      if (minutesMatch) {
        totalSeconds += parseInt(minutesMatch[1]) * 60;
      }

      // Match seconds
      const secondsMatch = text.match(/(\d+)s/);
      if (secondsMatch) {
        totalSeconds += parseInt(secondsMatch[1]);
      }

      return totalSeconds > 0 ? totalSeconds : null;
    }

    return null;
  }

  // ===== Search Functions =====
  function initializeSearch() {
    const searchInput = document.getElementById('search-input');

    if (searchInput) {
      // Debounce search to avoid excessive filtering
      let searchTimeout;
      searchInput.addEventListener('input', function () {
        clearTimeout(searchTimeout);
        searchTimeout = setTimeout(function () {
          state.filters.search = searchInput.value.toLowerCase();
          saveFiltersToURL();
          applyFilters();
        }, 300);
      });
    }
  }

  // ===== Model Tag Click Handlers =====
  function initializeModelTags() {
    // Add click handlers to model tags for filtering
    const modelTags = document.querySelectorAll('.model-tag');

    modelTags.forEach(function (tag) {
      tag.addEventListener('click', function () {
        const fullModel = this.getAttribute('data-model-full');
        if (fullModel) {
          // Set the model filter
          const modelFilter = document.getElementById('filter-model');
          if (modelFilter) {
            modelFilter.value = fullModel;
            state.filters.model = fullModel.toLowerCase();
            saveFiltersToURL();
            applyFilters();

            // Scroll to top to see the filter
            window.scrollTo({ top: 0, behavior: 'smooth' });
          }
        }
      });
    });
  }

  // ===== Detail Page Functions =====
  // Functions specific to run detail pages

  function initializeDetailPage() {
    // Add any detail page specific functionality here
    // For example, collapsible sections, test result filtering, etc.
  }

  // Check if we're on a detail page
  if (window.location.pathname.includes('/run_')) {
    initializeDetailPage();
  }

  // ===== Utility Functions =====

  /**
   * Format bytes to human-readable size
   */
  function formatBytes(bytes) {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
  }

  /**
   * Format duration in seconds to human-readable format
   */
  function formatDuration(seconds) {
    if (seconds < 60) return seconds.toFixed(1) + 's';
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = Math.floor(seconds % 60);
    return minutes + 'm ' + remainingSeconds + 's';
  }

  /**
   * Format date to locale string
   */
  function formatDate(dateString) {
    const date = new Date(dateString);
    if (isNaN(date.getTime())) return dateString;
    return date.toLocaleString();
  }

  // Export utility functions for use in HTML if needed
  window.LLMEval = {
    formatBytes: formatBytes,
    formatDuration: formatDuration,
    formatDate: formatDate,
    clearFilters: clearFilters,
  };
})();
