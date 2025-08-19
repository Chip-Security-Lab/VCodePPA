//SystemVerilog
//IEEE 1364-2005 Verilog
module sipo_register #(parameter N = 8) (
    input wire clk, rst, en,
    input wire s_in,
    output wire [N-1:0] p_out
);
    // Pipeline stage registers
    reg [N-1:0] shift_register;
    
    // Main data path - Input stage
    always @(posedge clk) begin
        if (rst)
            shift_register[0] <= 1'b0;
        else if (en)
            shift_register[0] <= s_in;
    end
    
    // Data propagation pipeline stages
    genvar i;
    generate
        for (i = 1; i < N; i = i + 1) begin : shift_pipeline_stage
            always @(posedge clk) begin
                if (rst)
                    shift_register[i] <= 1'b0;
                else if (en)
                    shift_register[i] <= shift_register[i-1];
            end
        end
    endgenerate
    
    // Output data path
    assign p_out = shift_register;
endmodule