from rest_framework.permissions import BasePermission

# ==========================================
# 1. نظام الصلاحيات المتقدم (RBAC) - للصلاحيات التفصيلية
# ==========================================
class HasPermission(BasePermission):
    """
    نظام الصلاحيات (RBAC):
    يتحقق مما إذا كان كائن الدور (role_obj) يمتلك الصلاحية لتنفيذ العملية الحالية.
    """
    def has_permission(self, request, view):
        # 1. رفض غير المسجلين
        if not request.user or not request.user.is_authenticated:
            return False
        
        # 2. مدير النظام (Super Admin) لديه كافة الصلاحيات دائماً
        if request.user.is_superuser or request.user.role == 'admin':
            return True
            
        # 3. التحقق من صلاحيات الموظف بناءً على كائن الدور (role_obj) وليس النص (role)
        required_module = getattr(view, 'required_module', None)
        required_action = getattr(view, 'required_action', None)
        
        if required_module and required_action:
            if not request.user.role_obj:
                return False # ليس لديه كائن دور محدد للصلاحيات التفصيلية
            
            # التحقق من الصلاحية عبر العلاقة permissions_rel الموجودة في models.py
            has_perm = request.user.role_obj.permissions_rel.filter(
                permission__module=required_module, 
                permission__action=required_action
            ).exists()
            return has_perm
            
        return True # في حال لم يتم تحديد قيود على الـ View


# ==========================================
# 2. حراس التوجيه السريع (Role Guards) لتأمين الـ APIs
# ==========================================

class IsMerchant(BasePermission):
    message = "عذراً، هذه الصلاحية مخصصة لأصحاب المتاجر فقط."

    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.role == 'store_admin')


class IsDriver(BasePermission):
    message = "عذراً، هذه الصلاحية مخصصة لكباتن التوصيل فقط."

    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.role == 'driver')


class IsSupervisor(BasePermission):
    message = "عذراً، هذه الصلاحية مخصصة للمشرفين فقط."

    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.role == 'supervisor')


class IsAdmin(BasePermission):
    message = "عذراً، هذه الصلاحية للإدارة العليا فقط."

    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and (request.user.role == 'admin' or request.user.is_superuser))


class IsAdminOrSupervisor(BasePermission):
    message = "عذراً، هذه الصلاحية مخصصة للإدارة والمشرفين فقط."

    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.role in ['admin', 'supervisor'])


class IsCustomer(BasePermission):
    message = "عذراً، هذه الصلاحية مخصصة للعملاء فقط."

    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.role == 'customer')