//SystemVerilog
module EdgeIVMU_pipelined (
    input clk,
    input rst,
    input [7:0] int_in,
    output [31:0] vector,
    output valid
);

    // ROM definition
    reg [31:0] vector_rom [0:7];
    integer i;

    initial begin
        for (i = 0; i < 8; i = i + 1) begin
            vector_rom[i] = 32'h5000_0000 + (i * 16);
        end
    end

    // Stage 0: Input Registering
    reg [7:0] int_in_s0_reg;
    reg [7:0] int_prev_s0_reg; // Previous int_in_s0_reg

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            int_in_s0_reg <= 8'h0;
            int_prev_s0_reg <= 8'h0;
        end else begin
            int_in_s0_reg <= int_in;
            int_prev_s0_reg <= int_in_s0_reg; // Capture previous cycle's int_in
        end
    end

    // Stage 1: Edge Detection, Index, and Valid Calculation
    wire [7:0] edge_detect_s1_comb;
    wire [2:0] edge_index_s1_comb; // Changed from reg to wire
    wire valid_s1_comb;

    reg [2:0] edge_index_s1_reg;
    reg valid_s1_reg;

    assign edge_detect_s1_comb = int_in_s0_reg & ~int_prev_s0_reg; // Uses registered inputs from Stage 0
    assign valid_s1_comb = |edge_detect_s1_comb; // Valid if any edge detected

    // Combinatorial Priority encoder using boolean logic (Optimized comparison chain)
    // Replaces the always @(*) block with parallel logic
    // edge_index_s1_comb[2] is set if the highest bit is 7, 6, 5, or 4
    assign edge_index_s1_comb[2] = edge_detect_s1_comb[7] | edge_detect_s1_comb[6] | edge_detect_s1_comb[5] | edge_detect_s1_comb[4];
    // edge_index_s1_comb[1] is set if the highest bit is 6, 3, or 2
    assign edge_index_s1_comb[1] = (~edge_detect_s1_comb[7] & edge_detect_s1_comb[6]) | (~edge_detect_s1_comb[7:4] & edge_detect_s1_comb[3]) | (~edge_detect_s1_comb[7:3] & edge_detect_s1_comb[2]);
    // edge_index_s1_comb[0] is set if the highest bit is 7, 5, 3, or 1
    assign edge_index_s1_comb[0] = edge_detect_s1_comb[7] | (~edge_detect_s1_comb[7:6] & edge_detect_s1_comb[5]) | (~edge_detect_s1_comb[7:4] & edge_detect_s1_comb[3]) | (~edge_detect_s1_comb[7:2] & edge_detect_s1_comb[1]);
    // When edge_detect_s1_comb is 8'b0000_0000, edge_index_s1_comb becomes 3'b000, matching the original default.

    always @(posedge clk or posedge rst) begin // Stage 1 Registers
        if (rst) begin
            valid_s1_reg <= 1'b0;
            edge_index_s1_reg <= 3'b000;
        end else begin
            valid_s1_reg <= valid_s1_comb; // Register the valid signal
            edge_index_s1_reg <= edge_index_s1_comb; // Register the calculated index
        end
    end

    // Stage 2: ROM Lookup and Output Registering
    wire [31:0] vector_s2_comb;
    reg [31:0] vector_s2_reg;
    reg valid_s2_reg;

    // Combinatorial ROM lookup using registered index from Stage 1
    assign vector_s2_comb = vector_rom[edge_index_s1_reg];

    // Output ports connected to Stage 2 registers
    assign vector = vector_s2_reg;
    assign valid = valid_s2_reg;

    always @(posedge clk or posedge rst) begin // Stage 2 Registers
        if (rst) begin
            vector_s2_reg <= 32'h0;
            valid_s2_reg <= 1'b0;
        end else begin
            // Update vector_s2_reg only if valid_s1_reg is high
            if (valid_s1_reg) begin
                 vector_s2_reg <= vector_s2_comb; // Update vector with lookup result
            end
            // vector_s2_reg retains its value if valid_s1_reg is low, mimicking original behavior
            valid_s2_reg <= valid_s1_reg; // Register the valid signal from Stage 1
        end
    end

endmodule