//SystemVerilog
module snapshot_buffer (
    input wire clk,
    input wire [31:0] live_data,
    input wire capture,
    output wire [31:0] snapshot_data
);
    reg [31:0] captured_data;
    reg capture_reg;
    reg [31:0] snapshot_data_reg;
    
    // 合并相同触发条件(posedge clk)的always块
    always @(posedge clk) begin
        captured_data <= live_data;
        capture_reg <= capture;
        
        if (capture_reg)
            snapshot_data_reg <= captured_data;
    end
    
    assign snapshot_data = snapshot_data_reg;
endmodule