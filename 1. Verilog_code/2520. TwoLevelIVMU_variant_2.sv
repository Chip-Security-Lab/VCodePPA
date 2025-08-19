//SystemVerilog
// SystemVerilog
module TwoLevelIVMU (
    input wire clock,
    input wire reset,
    input wire [31:0] irq_lines,
    input wire [31:0] group_priority_flat, // Modified to flattened array
    input wire ack, // New: Acknowledge signal from receiver
    output wire [31:0] handler_addr, // Changed to wire, driven by reg
    output wire req // Renamed from irq_active, changed to wire, driven by reg
);

    // Internal memory for vector table
    reg [31:0] vector_table [0:31];

    // Assign registered outputs to module ports
    reg [31:0] handler_addr_out_reg; // Final output register driven by handshake
    reg req_out_reg; // Final output register driven by handshake

    assign handler_addr = handler_addr_out_reg;
    assign req = req_out_reg;

    // --- Pipelining Stages ---

    // Stage 0: Combinational calculation of group pending and group priority mapping (feeds Stage 1)
    wire [7:0] group_pending_s0_comb;
    wire [3:0] group_priority_s0_comb [0:7]; // Extracted priority array (not used in fixed priority logic)

    genvar g;
    generate
        for (g = 0; g < 8; g = g + 1) begin: group_prio_map_s0
            assign group_priority_s0_comb[g] = group_priority_flat[g*4+3:g*4];
        end
    endgenerate

    generate
        for (g = 0; g < 8; g = g + 1) begin: group_gen_s0
            assign group_pending_s0_comb[g] = |irq_lines[g*4+3:g*4];
        end
    endgenerate

    // Stage 1: Register inputs and perform priority encoding
    reg [31:0] irq_lines_s1_reg;
    reg [7:0] group_pending_s1_reg;

    reg [3:0] active_group_s1_comb;
    reg [3:0] active_line_s1_comb;
    reg irq_pending_s1_comb;

    reg [3:0] active_group_s1_reg;
    reg [3:0] active_line_s1_reg;
    reg irq_pending_s1_reg;

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            irq_lines_s1_reg <= 32'b0;
            group_pending_s1_reg <= 8'b0;
            active_group_s1_reg <= 4'b0;
            active_line_s1_reg <= 4'b0;
            irq_pending_s1_reg <= 1'b0;
        end else begin
            irq_lines_s1_reg <= irq_lines;
            group_pending_s1_reg <= group_pending_s0_comb; // Register output of Stage 0
            active_group_s1_reg <= active_group_s1_comb;
            active_line_s1_reg <= active_line_s1_comb;
            irq_pending_s1_reg <= irq_pending_s1_comb;
        end
    end

    // Combinational logic for Stage 1 (priority encoding)
    // Uses registered inputs from Stage 0 (irq_lines_s1_reg, group_pending_s1_reg)
    always @(*) begin
        active_group_s1_comb = 4'd0;
        active_line_s1_comb = 4'd0;
        irq_pending_s1_comb = 1'b0;

        // Fixed priority check
        if (group_pending_s1_reg[0]) begin
            active_group_s1_comb = 4'd0;
            if (irq_lines_s1_reg[3]) begin
                active_line_s1_comb = 4'd3;
                irq_pending_s1_comb = 1;
            end else if (irq_lines_s1_reg[2]) begin
                active_line_s1_comb = 4'd2;
                irq_pending_s1_comb = 1;
            end else if (irq_lines_s1_reg[1]) begin
                active_line_s1_comb = 4'd1;
                irq_pending_s1_comb = 1;
            end else if (irq_lines_s1_reg[0]) begin
                active_line_s1_comb = 4'd0;
                irq_pending_s1_comb = 1;
            end
        end else if (group_pending_s1_reg[1]) begin
            active_group_s1_comb = 4'd1;
            if (irq_lines_s1_reg[7]) begin
                active_line_s1_comb = 4'd3;
                irq_pending_s1_comb = 1;
            end else if (irq_lines_s1_reg[6]) begin
                active_line_s1_comb = 4'd2;
                irq_pending_s1_comb = 1;
            end else if (irq_lines_s1_reg[5]) begin
                active_line_s1_comb = 4'd1;
                irq_pending_s1_comb = 1;
            end else if (irq_lines_s1_reg[4]) begin
                active_line_s1_comb = 4'd0;
                irq_pending_s1_comb = 1;
            end
        end else if (group_pending_s1_reg[2]) begin
            active_group_s1_comb = 4'd2;
            if (irq_lines_s1_reg[11]) begin
                active_line_s1_comb = 4'd3;
                irq_pending_s1_comb = 1;
            end else if (irq_lines_s1_reg[10]) begin
                active_line_s1_comb = 4'd2;
                irq_pending_s1_comb = 1;
            end else if (irq_lines_s1_reg[9]) begin
                active_line_s1_comb = 4'd1;
                irq_pending_s1_comb = 1;
            end else if (irq_lines_s1_reg[8]) begin
                active_line_s1_comb = 4'd0;
                irq_pending_s1_comb = 1;
            end
        end else if (group_pending_s1_reg[3]) begin
            active_group_s1_comb = 4'd3;
            if (irq_lines_s1_reg[15]) begin
                active_line_s1_comb = 4'd3;
                irq_pending_s1_comb = 1;
            end else if (irq_lines_s1_reg[14]) begin
                active_line_s1_comb = 4'd2;
                irq_pending_s1_comb = 1;
            end else if (irq_lines_s1_reg[13]) begin
                active_line_s1_comb = 4'd1;
                irq_pending_s1_comb = 1;
            end else if (irq_lines_s1_reg[12]) begin
                active_line_s1_comb = 4'd0;
                irq_pending_s1_comb = 1;
            end
        end else if (group_pending_s1_reg[4]) begin
            active_group_s1_comb = 4'd4;
            if (irq_lines_s1_reg[19]) begin
                active_line_s1_comb = 4'd3;
                irq_pending_s1_comb = 1;
            end else if (irq_lines_s1_reg[18]) begin
                active_line_s1_comb = 4'd2;
                irq_pending_s1_comb = 1;
            end else if (irq_lines_s1_reg[17]) begin
                active_line_s1_comb = 4'd1;
                irq_pending_s1_comb = 1;
            end else if (irq_lines_s1_reg[16]) begin
                active_line_s1_comb = 4'd0;
                irq_pending_s1_comb = 1;
            end
        end else if (group_pending_s1_reg[5]) begin
            active_group_s1_comb = 4'd5;
            if (irq_lines_s1_reg[23]) begin
                active_line_s1_comb = 4'd3;
                irq_pending_s1_comb = 1;
            end else if (irq_lines_s1_reg[22]) begin
                active_line_s1_comb = 4'd2;
                irq_pending_s1_comb = 1;
            end else if (irq_lines_s1_reg[21]) begin
                active_line_s1_comb = 4'd1;
                irq_pending_s1_comb = 1;
            end else if (irq_lines_s1_reg[20]) begin
                active_line_s1_comb = 4'd0;
                irq_pending_s1_comb = 1;
            end
        end else if (group_pending_s1_reg[6]) begin
            active_group_s1_comb = 4'd6;
            if (irq_lines_s1_reg[27]) begin
                active_line_s1_comb = 4'd3;
                irq_pending_s1_comb = 1;
            end else if (irq_lines_s1_reg[26]) begin
                active_line_s1_comb = 4'd2;
                irq_pending_s1_comb = 1;
            end else if (irq_lines_s1_reg[25]) begin
                active_line_s1_comb = 4'd1;
                irq_pending_s1_comb = 1;
            end else if (irq_lines_s1_reg[24]) begin
                active_line_s1_comb = 4'd0;
                irq_pending_s1_comb = 1;
            end
        end else if (group_pending_s1_reg[7]) begin
            active_group_s1_comb = 4'd7;
            if (irq_lines_s1_reg[31]) begin
                active_line_s1_comb = 4'd3;
                irq_pending_s1_comb = 1;
            end else if (irq_lines_s1_reg[30]) begin
                active_line_s1_comb = 4'd2;
                irq_pending_s1_comb = 1;
            end else if (irq_lines_s1_reg[29]) begin
                active_line_s1_comb = 4'd1;
                irq_pending_s1_comb = 1;
            end else if (irq_lines_s1_reg[28]) begin
                active_line_s1_comb = 4'd0;
                irq_pending_s1_comb = 1;
            end
        end
    end

    // Stage 2: Register Stage 1 outputs, calculate vector table index, perform lookup
    reg [3:0] active_group_s2_reg;
    reg [3:0] active_line_s2_reg;
    reg irq_pending_s2_reg;

    wire [4:0] vector_table_index_s2_comb; // 32 entries -> 5 bits
    wire [31:0] handler_addr_s2_comb;

    reg [31:0] handler_addr_s2_reg;

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            active_group_s2_reg <= 4'b0;
            active_line_s2_reg <= 4'b0;
            irq_pending_s2_reg <= 1'b0;
            handler_addr_s2_reg <= 32'b0;
        end else begin
            active_group_s2_reg <= active_group_s1_reg;
            active_line_s2_reg <= active_line_s1_reg;
            irq_pending_s2_reg <= irq_pending_s1_reg;
            handler_addr_s2_reg <= handler_addr_s2_comb;
        end
    end

    // Combinational logic for Stage 2 (index calculation and table lookup)
    // Uses registered inputs from Stage 1 (active_group_s2_reg, active_line_s2_reg)
    // Index calculation: group * 4 + line
    assign vector_table_index_s2_comb = (active_group_s2_reg << 2) | active_line_s2_reg;
    // Table lookup
    assign handler_addr_s2_comb = vector_table[vector_table_index_s2_comb];

    // Stage 3: Register Stage 2 outputs for Req-Ack handshake
    reg [31:0] handler_addr_s3_reg;
    reg irq_pending_s3_reg;

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            handler_addr_s3_reg <= 32'b0;
            irq_pending_s3_reg <= 1'b0;
        end else begin
            handler_addr_s3_reg <= handler_addr_s2_reg;
            irq_pending_s3_reg <= irq_pending_s2_reg;
        end
    end

    // Req-Ack Handshake Logic (uses Stage 3 outputs)
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            req_out_reg <= 1'b0;
            handler_addr_out_reg <= 32'b0;
        end else begin
            // State machine: IDLE (req_out_reg=0), SENDING (req_out_reg=1)
            if (req_out_reg == 1'b0) begin // Currently in IDLE state
                if (irq_pending_s3_reg == 1'b1) begin // A new interrupt is pending from the pipeline
                    req_out_reg <= 1'b1; // Move to SENDING state
                    handler_addr_out_reg <= handler_addr_s3_reg; // Load the new address
                end else begin // No interrupt pending from pipeline
                    req_out_reg <= 1'b0; // Stay in IDLE
                    // handler_addr_out_reg holds old value, doesn't matter as req is 0
                end
            end else begin // Currently in SENDING state (req_out_reg == 1)
                if (ack == 1'b1) begin // Receiver acknowledged
                    req_out_reg <= 1'b0; // Move back to IDLE state
                    // handler_addr_out_reg holds value until next req=1
                end else begin // Receiver not yet acknowledged
                    req_out_reg <= 1'b1; // Stay in SENDING state
                    // handler_addr_out_reg must be held stable
                end
            end
        end
    end

    // Vector table initialization
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1)
            vector_table[i] = 32'hFFF8_0000 + (i << 4);
    end

endmodule