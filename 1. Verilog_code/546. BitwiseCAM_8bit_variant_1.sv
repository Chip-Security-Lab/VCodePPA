//SystemVerilog
module cam_6 (
    input wire clk,
    input wire rst,
    input wire write_en,
    input wire [7:0] data_in,
    output reg match_flag
);

    // Pipeline stage 1 registers
    reg [7:0] data_in_stage1;
    reg write_en_stage1;
    reg [7:0] stored_bits_stage1;
    
    // Pipeline stage 2 registers
    reg [7:0] data_in_stage2;
    reg [7:0] stored_bits_stage2;
    reg [7:0] xor_result_stage2;
    
    // Pipeline stage 3 registers
    reg [7:0] xor_result_stage3;
    reg match_flag_stage3;

    // Stage 1: Input register
    always @(posedge clk) begin
        if (rst) begin
            data_in_stage1 <= 8'b0;
            write_en_stage1 <= 1'b0;
        end else begin
            data_in_stage1 <= data_in;
            write_en_stage1 <= write_en;
        end
    end

    // Stage 1: Storage register
    always @(posedge clk) begin
        if (rst) begin
            stored_bits_stage1 <= 8'b0;
        end else if (write_en) begin
            stored_bits_stage1 <= data_in;
        end
    end

    // Stage 2: Data pipeline
    always @(posedge clk) begin
        if (rst) begin
            data_in_stage2 <= 8'b0;
            stored_bits_stage2 <= 8'b0;
        end else begin
            data_in_stage2 <= data_in_stage1;
            stored_bits_stage2 <= stored_bits_stage1;
        end
    end

    // Stage 2: XOR operation
    always @(posedge clk) begin
        if (rst) begin
            xor_result_stage2 <= 8'b0;
        end else begin
            xor_result_stage2 <= stored_bits_stage1 ^ data_in_stage1;
        end
    end

    // Stage 3: XOR result pipeline
    always @(posedge clk) begin
        if (rst) begin
            xor_result_stage3 <= 8'b0;
        end else begin
            xor_result_stage3 <= xor_result_stage2;
        end
    end

    // Stage 3: Match flag generation
    always @(posedge clk) begin
        if (rst) begin
            match_flag_stage3 <= 1'b0;
        end else begin
            match_flag_stage3 <= &(~xor_result_stage2);
        end
    end

    // Output register
    always @(posedge clk) begin
        if (rst) begin
            match_flag <= 1'b0;
        end else begin
            match_flag <= match_flag_stage3;
        end
    end

endmodule