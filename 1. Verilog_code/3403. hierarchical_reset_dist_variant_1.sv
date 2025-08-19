//SystemVerilog
// SystemVerilog
module hierarchical_reset_dist (
    input  wire        clk,              // 系统时钟
    input  wire        global_rst,       // 全局复位信号
    input  wire [1:0]  domain_select,    // 域选择信号
    output wire [7:0]  subsystem_rst     // 子系统复位输出
);

    // 内部信号声明 - 分段流水线寄存器
    reg         global_rst_r;            // 全局复位寄存器
    reg [1:0]   domain_select_r;         // 域选择寄存器
    
    // 域复位计算的中间信号
    wire [3:0]  domain_rst;              // 各域的复位控制信号
    reg  [3:0]  domain_rst_r;            // 寄存器化的域复位信号
    
    // 第一级流水线：寄存输入信号
    always @(posedge clk) begin
        global_rst_r    <= global_rst;
        domain_select_r <= domain_select;
    end
    
    // 计算各域复位信号
    // 域0和域1接收直接全局复位
    assign domain_rst[0] = global_rst_r;
    assign domain_rst[1] = global_rst_r;
    
    // 域2和域3接收条件复位
    assign domain_rst[2] = global_rst_r & domain_select_r[0];
    assign domain_rst[3] = global_rst_r & domain_select_r[1];
    
    // 第二级流水线：寄存域复位信号
    always @(posedge clk) begin
        domain_rst_r <= domain_rst;
    end
    
    // 输出映射：将域复位信号映射到子系统输出
    // 每个域控制两个子系统
    assign subsystem_rst[1:0] = {2{domain_rst_r[0]}};
    assign subsystem_rst[3:2] = {2{domain_rst_r[1]}};
    assign subsystem_rst[5:4] = {2{domain_rst_r[2]}};
    assign subsystem_rst[7:6] = {2{domain_rst_r[3]}};

endmodule