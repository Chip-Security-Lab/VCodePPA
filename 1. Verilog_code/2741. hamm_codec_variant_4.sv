//SystemVerilog
module hamm_codec(
    input t_clk, t_rst,
    input [3:0] i_data,
    input i_encode_n_decode,
    output reg [6:0] o_encoded,
    output reg [3:0] o_decoded,
    output reg o_error
);

    // Pipeline stage 1 registers
    reg [3:0] r_data_stage1;
    reg r_encode_n_decode_stage1;
    
    // Pipeline stage 2 registers
    reg [3:0] r_data_stage2;
    reg r_encode_n_decode_stage2;
    reg [6:0] r_encoded_stage2;
    
    // Pipeline stage 3 registers for decode operation
    reg [2:0] r_syndrome_stage3;
    reg [6:0] r_encoded_stage3;
    
    // Intermediate calculation registers
    reg [2:0] r_partial_syndrome_stage2;
    
    // Buffered signals
    reg [6:0] r_encoded_buf1;
    reg [6:0] r_encoded_buf2;
    reg [3:0] r_data_buf1;
    reg [3:0] r_data_buf2;
    reg [6:0] r_encoded_stage2_buf;
    reg [6:0] r_encoded_stage3_buf;
    reg [6:0] w_encoded_buf;

    // Optimized encoding logic with buffering
    wire [6:0] w_encoded;
    assign w_encoded[0] = r_data_buf1[0] ^ r_data_buf1[1] ^ r_data_buf1[3];
    assign w_encoded[1] = r_data_buf1[0] ^ r_data_buf1[2] ^ r_data_buf1[3];
    assign w_encoded[2] = r_data_buf1[0];
    assign w_encoded[3] = r_data_buf1[1] ^ r_data_buf1[2] ^ r_data_buf1[3];
    assign w_encoded[4] = r_data_buf1[1];
    assign w_encoded[5] = r_data_buf1[2];
    assign w_encoded[6] = r_data_buf1[3];

    // Optimized syndrome calculation with buffering
    wire [2:0] w_partial_syndrome;
    assign w_partial_syndrome[0] = r_encoded_buf1[0] ^ r_encoded_buf1[2];
    assign w_partial_syndrome[1] = r_encoded_buf1[1] ^ r_encoded_buf1[2];
    assign w_partial_syndrome[2] = r_encoded_buf1[3] ^ r_encoded_buf1[4];

    wire [2:0] w_syndrome;
    assign w_syndrome[0] = w_partial_syndrome[0] ^ r_encoded_stage2_buf[4] ^ r_encoded_stage2_buf[6];
    assign w_syndrome[1] = w_partial_syndrome[1] ^ r_encoded_stage2_buf[5] ^ r_encoded_stage2_buf[6];
    assign w_syndrome[2] = w_partial_syndrome[2] ^ r_encoded_stage2_buf[5] ^ r_encoded_stage2_buf[6];

    always @(posedge t_clk or posedge t_rst) begin
        if (t_rst) begin
            r_data_stage1 <= 4'b0;
            r_encode_n_decode_stage1 <= 1'b0;
            r_data_stage2 <= 4'b0;
            r_encode_n_decode_stage2 <= 1'b0;
            r_encoded_stage2 <= 7'b0;
            r_partial_syndrome_stage2 <= 3'b0;
            r_syndrome_stage3 <= 3'b0;
            r_encoded_stage3 <= 7'b0;
            o_encoded <= 7'b0;
            o_decoded <= 4'b0;
            o_error <= 1'b0;
            r_encoded_buf1 <= 7'b0;
            r_encoded_buf2 <= 7'b0;
            r_data_buf1 <= 4'b0;
            r_data_buf2 <= 4'b0;
            r_encoded_stage2_buf <= 7'b0;
            r_encoded_stage3_buf <= 7'b0;
            w_encoded_buf <= 7'b0;
        end else begin
            // Buffer stage
            r_encoded_buf1 <= o_encoded;
            r_encoded_buf2 <= r_encoded_buf1;
            r_data_buf1 <= r_data_stage1;
            r_data_buf2 <= r_data_buf1;
            r_encoded_stage2_buf <= r_encoded_stage2;
            r_encoded_stage3_buf <= r_encoded_stage3;
            w_encoded_buf <= w_encoded;

            // Pipeline stage 1
            r_data_stage1 <= i_data;
            r_encode_n_decode_stage1 <= i_encode_n_decode;
            
            // Pipeline stage 2
            r_data_stage2 <= r_data_buf2;
            r_encode_n_decode_stage2 <= r_encode_n_decode_stage1;
            r_encoded_stage2 <= r_encode_n_decode_stage1 ? w_encoded_buf : r_encoded_buf2;
            r_partial_syndrome_stage2 <= w_partial_syndrome;
            
            // Pipeline stage 3
            r_encoded_stage3 <= r_encoded_stage2_buf;
            r_syndrome_stage3 <= w_syndrome;
            
            // Output stage
            if (r_encode_n_decode_stage2) begin
                o_encoded <= r_encoded_stage2_buf;
            end else begin
                o_error <= |r_syndrome_stage3;
                o_decoded <= {r_encoded_stage3_buf[6], r_encoded_stage3_buf[5], r_encoded_stage3_buf[4], r_encoded_stage3_buf[2]};
            end
        end
    end
endmodule