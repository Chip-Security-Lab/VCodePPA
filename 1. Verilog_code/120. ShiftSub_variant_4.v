module ShiftSub(
    input [7:0] a,
    input [7:0] b,
    output reg [7:0] res
);

    wire [7:0] b_shifted [7:0];
    wire [7:0] temp_res [7:0];
    wire [7:0] mux_out [7:0];
    wire [7:0] sub_out [7:0];
    wire [7:0] comp_out [7:0];
    
    // Generate shifted versions of b
    assign b_shifted[0] = b;
    assign b_shifted[1] = b << 1;
    assign b_shifted[2] = b << 2;
    assign b_shifted[3] = b << 3;
    assign b_shifted[4] = b << 4;
    assign b_shifted[5] = b << 5;
    assign b_shifted[6] = b << 6;
    assign b_shifted[7] = b << 7;
    
    // First stage
    assign comp_out[0] = (a >= b_shifted[0]);
    assign sub_out[0] = a - b_shifted[0];
    assign mux_out[0] = comp_out[0] ? sub_out[0] : a;
    assign temp_res[0] = mux_out[0];
    
    // Second stage
    assign comp_out[1] = (temp_res[0] >= b_shifted[1]);
    assign sub_out[1] = temp_res[0] - b_shifted[1];
    assign mux_out[1] = comp_out[1] ? sub_out[1] : temp_res[0];
    assign temp_res[1] = mux_out[1];
    
    // Third stage
    assign comp_out[2] = (temp_res[1] >= b_shifted[2]);
    assign sub_out[2] = temp_res[1] - b_shifted[2];
    assign mux_out[2] = comp_out[2] ? sub_out[2] : temp_res[1];
    assign temp_res[2] = mux_out[2];
    
    // Fourth stage
    assign comp_out[3] = (temp_res[2] >= b_shifted[3]);
    assign sub_out[3] = temp_res[2] - b_shifted[3];
    assign mux_out[3] = comp_out[3] ? sub_out[3] : temp_res[2];
    assign temp_res[3] = mux_out[3];
    
    // Fifth stage
    assign comp_out[4] = (temp_res[3] >= b_shifted[4]);
    assign sub_out[4] = temp_res[3] - b_shifted[4];
    assign mux_out[4] = comp_out[4] ? sub_out[4] : temp_res[3];
    assign temp_res[4] = mux_out[4];
    
    // Sixth stage
    assign comp_out[5] = (temp_res[4] >= b_shifted[5]);
    assign sub_out[5] = temp_res[4] - b_shifted[5];
    assign mux_out[5] = comp_out[5] ? sub_out[5] : temp_res[4];
    assign temp_res[5] = mux_out[5];
    
    // Seventh stage
    assign comp_out[6] = (temp_res[5] >= b_shifted[6]);
    assign sub_out[6] = temp_res[5] - b_shifted[6];
    assign mux_out[6] = comp_out[6] ? sub_out[6] : temp_res[5];
    assign temp_res[6] = mux_out[6];
    
    // Eighth stage
    assign comp_out[7] = (temp_res[6] >= b_shifted[7]);
    assign sub_out[7] = temp_res[6] - b_shifted[7];
    assign mux_out[7] = comp_out[7] ? sub_out[7] : temp_res[6];
    assign temp_res[7] = mux_out[7];
    
    always @(*) begin
        res = temp_res[7];
    end

endmodule