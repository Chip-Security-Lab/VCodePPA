//SystemVerilog
module pl_reg_async_load #(parameter W=8) (
    input  logic clk, rst_n, load,
    input  logic [W-1:0] async_data,
    output logic [W-1:0] q
);
    logic [W-1:0] q_reg;
    logic load_r;
    logic [W-1:0] async_data_r;
    
    // 使用并行复位寄存器，减少了复位路径的延迟
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            load_r <= 1'b0;
            async_data_r <= '0; // 使用SystemVerilog简化赋值
        end
        else begin
            load_r <= load;
            async_data_r <= async_data;
        end
    end
    
    // 优化的寄存器逻辑，使用always_ff明确指示时序逻辑
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            q_reg <= '0;
        else if (load_r) 
            q_reg <= async_data_r;
    end
    
    // 直接连接输出，合成工具会优化掉额外的延迟
    assign q = q_reg;
endmodule