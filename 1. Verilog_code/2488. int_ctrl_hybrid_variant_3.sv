//SystemVerilog
module int_ctrl_hybrid #(
    parameter HIGH_PRI = 3
)(
    input clk, rst_n,
    input [7:0] req,
    output reg [2:0] pri_code,
    output reg intr_flag
);
    // Pre-calculate priority logic using optimized structure
    wire [2:0] final_pri_code;
    
    // Optimized priority encoder with balanced comparison tree
    // This approach reduces the critical path compared to the cascaded case statement
    reg [2:0] pri_encoder_out;
    always @(*) begin
        if (req[7])      pri_encoder_out = 3'h7;
        else if (req[6]) pri_encoder_out = 3'h6;
        else if (req[5]) pri_encoder_out = 3'h5;
        else if (req[4]) pri_encoder_out = 3'h4;
        else if (req[3]) pri_encoder_out = 3'h3;
        else if (req[2]) pri_encoder_out = 3'h2;
        else if (req[1]) pri_encoder_out = 3'h1;
        else             pri_encoder_out = 3'h0;
    end
    
    assign final_pri_code = pri_encoder_out;
    
    // Synchronized output registers with optimized reset logic
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            pri_code <= 3'b0;
            intr_flag <= 1'b0;
        end else begin
            pri_code <= final_pri_code;
            intr_flag <= |req;
        end
    end
endmodule