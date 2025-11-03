pub const TerminalInfo = struct {
    width: usize = 0,
    height: usize = 0,
    supports_true_color: bool = false,
    max_colors: usize = 16,
};

pub const Terminal = struct {
    pub fn init() Terminal {
        return Terminal{};
    }

    pub fn queryInfo(_: Terminal) TerminalInfo {
        return TerminalInfo{
            .width = 80,
            .height = 24,
            .supports_true_color = true,
            .max_colors = 256,
        };
    }
};
