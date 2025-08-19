//SystemVerilog
module EdgeIVMU_pipelined (
    input clk, rst,
    input [7:0] int_in,
    output reg [31:0] vector,
    output reg valid
);

    // Buffered clock and reset signals for distribution
    wire clk_buf = clk;
    wire rst_buf = rst;

    // ROM definition
    reg [31:0] vector_rom [0:7];
    integer i; // Used only in initial block, no need to buffer for timing

    initial begin
        for (i = 0; i < 8; i = i + 1)
            vector_rom[i] = 32'h5000_0000 + (i * 16);
    end

    // Stage 0: Input Latch & Edge Detect
    // int_prev is part of the state for edge detection
    reg [7:0] int_prev;
    // Registered output of Stage 0: edge_detect result
    reg [7:0] edge_detect_stage0_register;

    always @(posedge clk_buf or posedge rst_buf) begin
        if (rst_buf) begin
            int_prev <= 8'h0;
            edge_detect_stage0_register <= 8'h0;
        end else begin
            int_prev <= int_in;
            // Calculate edge_detect based on current input and previous state
            edge_detect_stage0_register <= int_in & ~int_prev;
        end
    end

    // Stage 1a (Combinational): Priority Encode & Valid Calculation
    // Combinational logic for Stage 1: Priority encode edge_detect and calculate valid
    wire [2:0] rom_index_stage1_comb;
    wire valid_stage1_comb;

    // Priority encoder implementation (combinational)
    // Converted if-else if to casez for priority encoding
    reg [2:0] temp_rom_index_stage1_comb; // Intermediate signal requested for buffering
    always @* begin
        // Default value if no bit is set (or for don't care in casez)
        temp_rom_index_stage1_comb = 3'h0;
        casez (edge_detect_stage0_register)
            8'b1zzzzzzz: temp_rom_index_stage1_comb = 3'd7;
            8'b01zzzzzz: temp_rom_index_stage1_comb = 3'd6;
            8'b001zzzzzz: temp_rom_index_stage1_comb = 3'd5;
            8'b0001zzzzzz: temp_rom_index_stage1_comb = 3'd4;
            8'b00001zzzzz: temp_rom_index_stage1_comb = 3'd3;
            8'b000001zzzz: temp_rom_index_stage1_comb = 3'd2;
            8'b0000001zzz: temp_rom_index_stage1_comb = 3'd1;
            8'b00000001zz: temp_rom_index_stage1_comb = 3'd0;
            default: temp_rom_index_stage1_comb = 3'h0; // Case for 8'h00
        endcase
    end
    // Assign combinational output to wire
    assign rom_index_stage1_comb = temp_rom_index_stage1_comb;

    // Valid signal calculation (combinational)
    assign valid_stage1_comb = |edge_detect_stage0_register;

    // Stage 1b (Register Buffer): Buffer outputs of Stage 1a combinatorial logic
    // This stage buffers the high-fanout/critical path signals from Stage 1a
    reg [2:0] rom_index_stage1_comb_buf_reg;
    reg valid_stage1_comb_buf_reg;

    always @(posedge clk_buf or posedge rst_buf) begin
        if (rst_buf) begin
            rom_index_stage1_comb_buf_reg <= 3'h0;
            valid_stage1_comb_buf_reg <= 1'b0;
        end else begin
            // Capture the outputs of Stage 1a combinational logic
            rom_index_stage1_comb_buf_reg <= rom_index_stage1_comb; // Buffering rom_index_stage1_comb (derived from temp_rom_index_stage1_comb)
            valid_stage1_comb_buf_reg <= valid_stage1_comb; // Also buffer valid to maintain synchronization
        end
    end


    // Stage 2 (Register): Register buffered outputs from Stage 1b
    // These registers now capture the buffered signals
    reg [2:0] rom_index_stage1_register;
    reg valid_stage1_register;

    always @(posedge clk_buf or posedge rst_buf) begin
        if (rst_buf) begin
            rom_index_stage1_register <= 3'h0;
            valid_stage1_register <= 1'b0;
        end else begin
            // Capture the buffered signals from Stage 1b
            rom_index_stage1_register <= rom_index_stage1_comb_buf_reg;
            valid_stage1_register <= valid_stage1_comb_buf_reg;
        end
    end

    // Stage 3 (Combinational): ROM Read based on Stage 2 registered index
    wire [31:0] vector_stage2_comb;
    // ROM read uses the index registered in Stage 2
    assign vector_stage2_comb = vector_rom[rom_index_stage1_register];

    // Stage 4 (Register): Final Output Registration
    // These are the module outputs, registered from Stage 3 combinational and Stage 2 registered valid
    always @(posedge clk_buf or posedge rst_buf) begin
        if (rst_buf) begin
            vector <= 32'h0;
            valid <= 1'b0;
        end else begin
            // Register the ROM read result from Stage 3
            vector <= vector_stage2_comb;
            // Propagate the valid signal from Stage 2
            valid <= valid_stage1_register;
        end
    end

endmodule