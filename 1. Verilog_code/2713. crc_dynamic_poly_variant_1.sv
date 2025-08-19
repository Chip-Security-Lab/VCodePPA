//SystemVerilog
module crc_dynamic_poly #(parameter WIDTH=16)(
    input clk, reset_n, load_poly,
    input [WIDTH-1:0] data_in, new_poly,
    output reg [WIDTH-1:0] crc,
    output reg valid_out
);

    // Pipeline registers
    reg [WIDTH-1:0] poly_reg;
    reg [WIDTH-1:0] data_stage1;
    reg [WIDTH-1:0] crc_stage1;
    reg [WIDTH-1:0] temp_xor_stage1;
    reg [WIDTH-1:0] result_stage2;
    reg [WIDTH-1:0] borrow_chain_stage2;
    reg valid_stage1, valid_stage2;

    // Stage 1: XOR and initial borrow calculation
    always @(*) begin
        temp_xor_stage1 = data_stage1 ^ (crc_stage1[WIDTH-1] ? poly_reg : 0);
        borrow_chain_stage2[0] = 0;
    end

    // Stage 2: Subtraction calculation
    always @(*) begin
        for (integer i = 0; i < WIDTH; i = i + 1) begin
            if (i < WIDTH-1) begin
                result_stage2[i] = crc_stage1[i+1] ^ temp_xor_stage1[i] ^ borrow_chain_stage2[i];
                borrow_chain_stage2[i+1] = (borrow_chain_stage2[i] & ~(crc_stage1[i+1] ^ temp_xor_stage1[i])) | 
                                         (~crc_stage1[i+1] & temp_xor_stage1[i]);
            end else begin
                result_stage2[WIDTH-1] = 0 ^ temp_xor_stage1[WIDTH-1] ^ borrow_chain_stage2[WIDTH-1];
            end
        end
    end

    // Pipeline control
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            data_stage1 <= 0;
            crc_stage1 <= 0;
            valid_stage1 <= 0;
            valid_stage2 <= 0;
            valid_out <= 0;
            crc <= 0;
        end else begin
            // Stage 1 registers
            data_stage1 <= data_in;
            crc_stage1 <= crc;
            valid_stage1 <= 1'b1;
            
            // Stage 2 registers
            valid_stage2 <= valid_stage1;
            
            // Output stage
            valid_out <= valid_stage2;
            if (load_poly) 
                poly_reg <= new_poly;
            else if (valid_stage2)
                crc <= result_stage2;
        end
    end
endmodule