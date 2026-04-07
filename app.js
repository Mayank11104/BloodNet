var app = angular.module('bloodNetApp', ['ngRoute']);

// ============================================
// ROUTES
// ============================================
app.config(function($routeProvider) {
    $routeProvider
        .when('/home',     { templateUrl: 'views/home.html',     controller: 'HomeCtrl'     })
        .when('/donors',   { templateUrl: 'views/donors.html',   controller: 'DonorCtrl'    })
        .when('/stock',    { templateUrl: 'views/stock.html',    controller: 'StockCtrl'    })
        .when('/request',  { templateUrl: 'views/request.html',  controller: 'RequestCtrl'  })
        .when('/track',    { templateUrl: 'views/track.html',    controller: 'TrackCtrl'    })
        .when('/login',    { templateUrl: 'views/login.html',    controller: 'AuthCtrl'     })
        .when('/register', { templateUrl: 'views/register.html', controller: 'RegisterCtrl' })
        .when('/register/seeker', { templateUrl: 'views/register-seeker.html', controller: 'RegisterSeekerCtrl' })
        .when('/profile',  { templateUrl: 'views/profile.html',  controller: 'ProfileCtrl'  })
        .when('/admin',    { templateUrl: 'views/admin.html',    controller: 'AdminCtrl'    })
        .otherwise({ redirectTo: '/home' });
});

// ============================================
// GLOBAL AUTH SERVICE
// ============================================
app.service('AuthService', function() {
    return {
        getUser: function() {
            var u = localStorage.getItem('bloodnet_user');
            return u ? JSON.parse(u) : null;
        },
        setUser: function(user) {
            localStorage.setItem('bloodnet_user', JSON.stringify(user));
        },
        getProfile: function() {
            var p = localStorage.getItem('bloodnet_profile');
            return p ? JSON.parse(p) : null;
        },
        setProfile: function(profile) {
            localStorage.setItem('bloodnet_profile', JSON.stringify(profile));
        },
        logout: function() {
            localStorage.removeItem('bloodnet_user');
            localStorage.removeItem('bloodnet_profile');
        },
        isLoggedIn: function() {
            return !!localStorage.getItem('bloodnet_user');
        }
    };
});

// ============================================
// ROOT / NAV CONTROLLER
// ============================================
app.controller('NavCtrl', function($scope, $rootScope, $location, AuthService) {
    $rootScope.currentUser = AuthService.getUser();

    $rootScope.$on('userLoggedIn', function(e, user) {
        $rootScope.currentUser = user;
    });

    $scope.currentUser = $rootScope.currentUser;

    $scope.logout = function() {
        AuthService.logout();
        $rootScope.currentUser = null;
        $scope.currentUser = null;
        $location.path('/home');
    };

    $scope.toggleMenu = function() {
        document.querySelector('.nav-links').classList.toggle('open');
    };

    $rootScope.showAlert = function(message, type) {
        $rootScope.globalAlert = { message: message, type: type || 'success' };
        setTimeout(function() {
            $rootScope.$apply(function() { $rootScope.globalAlert = null; });
        }, 4000);
    };

    $rootScope.clearAlert = function() { $rootScope.globalAlert = null; };
});

// ============================================
// HOME CONTROLLER
// ============================================
app.controller('HomeCtrl', function($scope, $http) {
    // Load blood stock summary (group by blood_group, sum units)
    $http.get('api/stock.php').then(function(res) {
        var stockMap = {};
        res.data.data.forEach(function(s) {
            if (!stockMap[s.blood_group]) {
                stockMap[s.blood_group] = { blood_group: s.blood_group, total: 0 };
            }
            stockMap[s.blood_group].total += parseInt(s.units_available);
        });
        $scope.stockSummary = Object.values(stockMap);
    });

    // Load cities
    $http.get('api/cities.php').then(function(res) {
        $scope.cities = res.data.data;
    });

    // Stats
    $scope.stats = [
        { icon: 'fas fa-city',       value: '12',    label: 'Cities'         },
        { icon: 'fas fa-hospital',   value: '12',    label: 'Blood Banks'    },
        { icon: 'fas fa-tint',       value: '8',     label: 'Blood Groups'   },
        { icon: 'fas fa-heart',      value: '24/7',  label: 'Support'        }
    ];
});

// ============================================
// DONOR SEARCH CONTROLLER
// ============================================
app.controller('DonorCtrl', function($scope, $http) {
    $scope.filter  = {};
    $scope.donors  = [];
    $scope.loading = false;
    $scope.searched = false;

    $scope.bloodGroups = ['A+','A-','B+','B-','O+','O-','AB+','AB-'];

    $http.get('api/cities.php').then(function(res) {
        $scope.cities = res.data.data;
    });

    $scope.searchDonors = function() {
        $scope.loading  = true;
        $scope.searched = true;
        var url = 'api/donors.php?available=1';
        if ($scope.filter.blood_group) url += '&blood_group=' + $scope.filter.blood_group;
        if ($scope.filter.city_id)     url += '&city_id='     + $scope.filter.city_id;

        $http.get(url).then(function(res) {
            $scope.donors  = res.data.data;
            $scope.loading = false;
        });
    };
});

// ============================================
// BLOOD STOCK CONTROLLER
// ============================================
app.controller('StockCtrl', function($scope, $http) {
    $scope.selectedCity = '';
    $scope.loading = true;

    $http.get('api/cities.php').then(function(res) {
        $scope.cities = res.data.data;
    });

    $http.get('api/stock.php').then(function(res) {
        $scope.allStock = res.data.data;
        $scope.loading  = false;
        $scope.groupByCity();
    });

    $scope.groupByCity = function() {
        var grouped = {};
        var data = $scope.allStock;
        if ($scope.selectedCity) {
            data = data.filter(function(s) {
                return s.city_id == $scope.selectedCity;
            });
        }
        data.forEach(function(s) {
            if (!grouped[s.city_name]) {
                grouped[s.city_name] = {
                    city: s.city_name,
                    state: s.state,
                    bank: s.bank_name,
                    contact: s.bank_contact,
                    stock: []
                };
            }
            grouped[s.city_name].stock.push(s);
        });
        $scope.groupedStock = Object.values(grouped);
    };

    $scope.getStockClass = function(units) {
        if (units <= 2)  return 'critical';
        if (units <= 5)  return 'low';
        if (units <= 10) return 'medium';
        return 'good';
    };

    $scope.filterCity = function() { $scope.groupByCity(); };
});

// ============================================
// REQUEST BLOOD CONTROLLER
// ============================================
app.controller('RequestCtrl', function($scope, $http, $rootScope, AuthService) {
    $scope.step        = 1;
    $scope.formData    = { severity: 'Medium', is_emergency: false };
    $scope.submitted   = false;
    $scope.trackingId  = '';
    $scope.bloodGroups = ['A+','A-','B+','B-','O+','O-','AB+','AB-'];
    $scope.incidentTypes = ['Accident','Surgery','Cancer','Childbirth','Other'];

    var user = AuthService.getUser();
    if (user) {
        $scope.formData.seeker_id = user.id;
        $scope.formData.contact   = user.phone || '';
        $scope.formData.city_id   = user.city_id || '';
    }
    $scope.isLoggedIn = !!user;

    $http.get('api/cities.php').then(function(res) {
        $scope.cities = res.data.data;
    });

    $scope.nextStep = function() { $scope.step = 2; };
    $scope.prevStep = function() { $scope.step = 1; };

    $scope.submitRequest = function() {
        if (!$scope.formData.seeker_id) {
            $rootScope.showAlert('Please login to submit a blood request', 'error');
            return;
        }
        $scope.submitting = true;
        $http.post('api/requests.php', $scope.formData).then(function(res) {
            if (res.data.success) {
                $scope.submitted  = true;
                $scope.trackingId = res.data.tracking_id;
                $scope.submitting = false;
            }
        }, function() {
            $rootScope.showAlert('Failed to submit request. Try again.', 'error');
            $scope.submitting = false;
        });
    };
});
// ============================================
// REGISTER SEEKER CONTROLLER
// ============================================
app.controller('RegisterSeekerCtrl', function($scope, $http, $location, $rootScope) {
    $scope.formData = {};
    $scope.error    = '';
    $scope.loading  = false;

    $http.get('api/cities.php').then(function(res) {
        $scope.cities = res.data.data;
    });

    $scope.register = function() {
        $scope.loading = true;
        $scope.error   = '';

        // Seekers register as plain users (role = seeker)
        var payload = {
            username  : $scope.formData.username,
            email     : $scope.formData.email,
            password  : $scope.formData.password,
            phone     : $scope.formData.phone,
            full_name : $scope.formData.full_name,
            city_id   : $scope.formData.city_id,
            role      : 'seeker'
        };

        $http.post('api/register-seeker.php', payload).then(function(res) {
            if (res.data.success) {
                $rootScope.showAlert('Registration successful! Please login.', 'success');
                $location.path('/login');
            } else {
                $scope.error   = res.data.error;
                $scope.loading = false;
            }
        }, function(err) {
            $scope.error   = err.data ? err.data.error : 'Registration failed.';
            $scope.loading = false;
        });
    };
});

// ============================================
// TRACK REQUEST CONTROLLER
// ============================================
app.controller('TrackCtrl', function($scope, $http) {
    $scope.trackingId = '';
    $scope.result     = null;
    $scope.notFound   = false;
    $scope.loading    = false;

    $scope.trackRequest = function() {
        if (!$scope.trackingId) return;
        $scope.loading  = true;
        $scope.result   = null;
        $scope.notFound = false;

        $http.get('api/requests.php?tracking_id=' + $scope.trackingId).then(function(res) {
            $scope.result  = res.data;
            $scope.loading = false;
        }, function() {
            $scope.notFound = true;
            $scope.loading  = false;
        });
    };

    $scope.getStatusClass = function(status) {
        var map = {
            'Pending':    'status-pending',
            'Processing': 'status-processing',
            'Approved':   'status-approved',
            'Fulfilled':  'status-fulfilled',
            'Rejected':   'status-rejected'
        };
        return map[status] || '';
    };
});

// ============================================
// AUTH CONTROLLER (Login)
// ============================================
app.controller('AuthCtrl', function($scope, $http, $location, $rootScope, AuthService) {
    $scope.loginData  = {};
    $scope.loginError = '';
    $scope.loading    = false;

    $scope.login = function() {
        $scope.loading    = true;
        $scope.loginError = '';

        $http.post('api/login.php', $scope.loginData).then(function(res) {
            if (res.data.success) {
                AuthService.setUser(res.data.user);
                if (res.data.profile) AuthService.setProfile(res.data.profile);
                $rootScope.currentUser = res.data.user;
                $rootScope.$broadcast('userLoggedIn', res.data.user);
                $rootScope.showAlert('Welcome back, ' + res.data.user.full_name + '!', 'success');

                if (res.data.user.role === 'admin')  $location.path('/admin');
                else if (res.data.user.role === 'donor') $location.path('/profile');
                else $location.path('/home');
            } else {
                $scope.loginError = res.data.error;
            }
            $scope.loading = false;
        }, function() {
            $scope.loginError = 'Server error. Try again.';
            $scope.loading    = false;
        });
    };
});

// ============================================
// REGISTER CONTROLLER
// ============================================
app.controller('RegisterCtrl', function($scope, $http, $location, $rootScope) {
    $scope.step        = 1;
    $scope.formData    = {};
    $scope.healthData  = {};
    $scope.bloodGroups = ['A+','A-','B+','B-','O+','O-','AB+','AB-'];
    $scope.error       = '';
    $scope.loading     = false;

    $http.get('api/cities.php').then(function(res) {
        $scope.cities = res.data.data;
    });

    $scope.nextStep = function() {
        $scope.step = 2;
    };

    $scope.prevStep = function() {
        $scope.step = 1;
    };

    $scope.register = function() {
        $scope.loading = true;
        $scope.error   = '';

        var payload = Object.assign({}, $scope.formData, $scope.healthData);

        $http.post('api/donors.php', payload).then(function(res) {
            if (res.data.success) {
                $rootScope.showAlert('Registration successful! Please login.', 'success');
                $location.path('/login');
            } else {
                $scope.error   = res.data.error;
                $scope.loading = false;
            }
        }, function(err) {
            $scope.error   = err.data ? err.data.error : 'Registration failed.';
            $scope.loading = false;
        });
    };
});

// ============================================
// PROFILE CONTROLLER (Donor)
// ============================================
app.controller('ProfileCtrl', function($scope, $http, $location, AuthService) {
    var user = AuthService.getUser();
    if (!user || user.role !== 'donor') {
        $location.path('/login');
        return;
    }

    $scope.user    = user;
    $scope.profile = AuthService.getProfile();
    $scope.donations = [];
    $scope.notifications = [];

    // Load donation history
    $http.get('api/donations.php?donor_id=' + user.id).then(function(res) {
        if (res.data.success) $scope.donations = res.data.data;
    });

    // Load notifications
    $http.get('api/notifications.php?user_id=' + user.id).then(function(res) {
        if (res.data.success) $scope.notifications = res.data.data;
    });

    $scope.creditPercent = function() {
        if (!$scope.profile) return 0;
        return Math.min(($scope.profile.total_credits % 100), 100);
    };

    $scope.toggleAvailability = function() {
        var newVal = $scope.profile.is_available == 1 ? 0 : 1;
        $http.put('api/donors.php', {
            user_id: user.id,
            is_available: newVal
        }).then(function(res) {
            if (res.data.success) {
                $scope.profile.is_available = newVal;
                AuthService.setProfile($scope.profile);
            }
        });
    };
});

// ============================================
// ADMIN CONTROLLER
// ============================================
app.controller('AdminCtrl', function($scope, $http, $rootScope, AuthService) {
    var user = AuthService.getUser();
    if (!user || user.role !== 'admin') {
        window.location.href = '#!/login';
        return;
    }

    $scope.activeTab   = 'dashboard';
    $scope.user        = user;
    $scope.stats       = {};
    $scope.donors      = [];
    $scope.requests    = [];
    $scope.stock       = [];
    $scope.statusFilter = '';

    $scope.setTab = function(tab) { $scope.activeTab = tab; };

    // Load everything
    $scope.loadDashboard = function() {
        $http.get('api/donors.php').then(function(res) {
            $scope.donors    = res.data.data;
            $scope.stats.donors = res.data.count;
        });
        $http.get('api/requests.php').then(function(res) {
            $scope.requests  = res.data.data;
            $scope.stats.requests = res.data.count;
            $scope.stats.pending  = res.data.data.filter(function(r) {
                return r.status === 'Pending';
            }).length;
        });
        $http.get('api/stock.php').then(function(res) {
            $scope.stock     = res.data.data;
            $scope.stats.critical = res.data.data.filter(function(s) {
                return s.units_available <= 3;
            }).length;
        });
    };

    $scope.loadDashboard();

    $scope.updateStatus = function(req, status) {
        $http.put('api/requests.php', {
            id: req.id,
            status: status,
            updated_by: user.id,
            notes: 'Updated by admin'
        }).then(function(res) {
            if (res.data.success) {
                req.status = status;
                $rootScope.showAlert('Request ' + status, 'success');
            }
        });
    };

    $scope.updateStock = function(item) {
        $http.put('api/stock.php', {
            bank_id:         item.id,
            blood_group:     item.blood_group,
            units_available: item.units_available
        }).then(function(res) {
            if (res.data.success) {
                $rootScope.showAlert('Stock updated!', 'success');
            }
        });
    };

    $scope.getStockClass = function(units) {
        if (units <= 2)  return 'critical';
        if (units <= 5)  return 'low';
        return 'good';
    };
});