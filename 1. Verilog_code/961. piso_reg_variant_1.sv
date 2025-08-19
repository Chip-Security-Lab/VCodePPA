//SystemVerilog
module piso_reg (
    input wire clk,
    input wire clear_b,
    input wire load,
    input wire [7:0] parallel_in,
    output wire serial_out
);
    reg [7:0] data_pre;
    reg serial_out_reg;
    
    // Pre-compute next state logic
    always @(posedge clk or negedge clear_b) begin: pre_computation
        if (!clear_b) begin
            data_pre <= 8'h00;
        end else if (load) begin
            data_pre <= parallel_in;
        end else begin
            data_pre <= {data_pre[6:0], 1'b0};
        end
    end
    
    // Register the output separately
    always @(posedge clk or negedge clear_b) begin: output_reg
        if (!clear_b) begin
            serial_out_reg <= 1'b0;
        end else begin
            serial_out_reg <= data_pre[7];
        end
    end
    
    // Connect registered output
    assign serial_out = serial_out_reg;
    
    // 初始化块，确保仿真和综合行为一致
    initial begin
        data_pre = 8'h00;
        serial_out_reg = 1'b0;
    end
    
endmodule