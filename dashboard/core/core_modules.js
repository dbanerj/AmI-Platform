var App = App || {};

App.main_modules = {
    // Core modules
    'cs': 'cs',
    'coffee-script': 'coffee-script',
    'core/constants': 'core/constants',
    'interceptor': 'core/interceptor',
    'loader': 'core/loader',
    'logger': 'core/logging/server_logger',
    'logger_store': 'core/logging/logger_store',
    'mozaic_module': 'core/module',
    'auth': 'core/auth',
    'base_model': 'core/base_model',
    'base_collection': 'core/base_collection',
    'layout': 'core/layout',
    'scrollable_widget': 'core/scrollable_widget',
    'widget': 'core/widget/widget',
    'profiler': 'core/profiler',
    'widget_starter': 'core/widget_starter',
    'channels_utils': 'core/channels_utils',
    'datasource': 'core/datasource/datasource',
    'pubsub': 'core/pubsub',
    'router': 'core/router',
    'controller': 'core/controller',
    'core/utils': 'core/utils',
    'utils/urls': 'core/utils/urls',
    'utils/time': 'core/utils/time',
    'utils/dom': 'core/utils/dom',
    'utils/images': 'core/utils/images',
    'utils/misc': 'core/utils/misc',
    'fixtures': 'core/fixtures-loader',
    'loading_animation': 'core/loading_animation',
    'modal_window': 'core/modal_window',
    'application_controller': 'core/application_controller',
    'context_processors': 'core/context_processors',
    'flags_collection': 'core/flags_collection',

    // Core collections
    'collection/raw_data': 'core/raw_data',

    // Core widgets
    'widget/base_form': 'core/base_widgets/base_form',
    'widget/delete_form': 'core/base_widgets/delete_form',
    'widget/update_form': 'core/base_widgets/update_form',
    'widget/widget_editor': 'core/base_widgets/widget_editor',
    'widget/item_count': 'core/base_widgets/item_count',
    'widget/user_item_count': 'core/base_widgets/user_item_count',
    'widget/order_by': 'core/base_widgets/order_by',
    'widget/url': 'core/base_widgets/url',
    'widget/mediator_widget': 'core/base_widgets/mediator_widget',
    'widget/translate_text': 'core/base_widgets/translate_text',
    'widget/wizard': 'core/base_widgets/wizard',
    'widget/list': 'core/base_widgets/list',
    'widget/notifications': 'core/base_widgets/notifications',
    'widget/notification_bar': 'core/base_widgets/notification_bar',
    'widget/autocomplete': 'core/base_widgets/autocomplete',
};

// This is actually how we check if this is being ran
// in node.js enviromnent, _module_ being an omnipresent
// entity there
if (typeof module != 'undefined') {
    module.exports.core_modules = App.main_modules;
}
