//SystemVerilog
module ram_based_ring #(parameter ADDR_WIDTH=4) (
    input logic clk, rst,
    output logic [2**ADDR_WIDTH-1:0] ram_out
);
    // 流水线阶段寄存器
    logic [ADDR_WIDTH-1:0] addr_stage1, addr_stage2;
    logic [2**ADDR_WIDTH-1:0] ram_out_stage1, ram_out_stage2;
    logic valid_stage1, valid_stage2;
    
    // 流水线阶段1：地址计算和数据准备
    logic [ADDR_WIDTH-1:0] next_addr;
    logic [2**ADDR_WIDTH-1:0] rotated_data;
    
    // 为rotated_data信号添加缓冲寄存器
    logic [2**ADDR_WIDTH-1:0] rotated_data_buf [3:0]; // 4个缓冲寄存器
    
    assign next_addr = addr_stage1 + 1;
    assign rotated_data = rst ? {{(2**ADDR_WIDTH-1){1'b0}}, 1'b1} : {ram_out[0], ram_out[2**ADDR_WIDTH-1:1]};
    
    // 流水线阶段2：处理和预输出
    logic [2**ADDR_WIDTH-1:0] processed_data;
    
    // 根据高扇出信号的负载情况选择适当的缓冲寄存器
    assign processed_data = valid_stage2 ? ram_out_stage2 : rotated_data_buf[0];
    
    // 流水线寄存器更新
    always_ff @(posedge clk) begin
        // 更新rotated_data的缓冲寄存器
        rotated_data_buf[0] <= rotated_data;
        rotated_data_buf[1] <= rotated_data;
        rotated_data_buf[2] <= rotated_data;
        rotated_data_buf[3] <= rotated_data;
        
        // 阶段1寄存器
        if (rst) begin
            addr_stage1 <= '0;
            valid_stage1 <= 1'b0;
            ram_out_stage1 <= {{(2**ADDR_WIDTH-1){1'b0}}, 1'b1}; // 初始值
        end else begin
            addr_stage1 <= next_addr;
            valid_stage1 <= 1'b1;
            ram_out_stage1 <= rotated_data_buf[1]; // 使用缓冲的数据
        end
        
        // 阶段2寄存器
        if (rst) begin
            addr_stage2 <= '0;
            valid_stage2 <= 1'b0;
            ram_out_stage2 <= {{(2**ADDR_WIDTH-1){1'b0}}, 1'b1}; // 初始值
        end else begin
            addr_stage2 <= addr_stage1;
            valid_stage2 <= valid_stage1;
            ram_out_stage2 <= ram_out_stage1;
        end
        
        // 输出寄存器
        ram_out <= processed_data;
    end
endmodule