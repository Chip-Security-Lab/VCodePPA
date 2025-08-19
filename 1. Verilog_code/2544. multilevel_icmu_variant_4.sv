//SystemVerilog
module multilevel_icmu (
    input clock, resetn,
    input [7:0] interrupts,
    input [15:0] priority_level_flat, // 修改为扁平化数组
    input ack_done,
    output reg [2:0] int_number,
    output reg [31:0] saved_context,
    input [31:0] current_context
);
    // Internal signals and registers
    wire [1:0] priority_level [0:7]; // 内部数组
    reg [7:0] level0_mask, level1_mask, level2_mask, level3_mask; // Combinatorial outputs
    reg [1:0] current_level;
    reg handle_active;

    // Added registers for buffering high-fanout signals
    reg [7:0] interrupts_r;
    reg [7:0] level0_mask_r, level1_mask_r, level2_mask_r, level3_mask_r;

    integer i; // Loop variable for combinatorial block

    // From flattened array extract priority (combinatorial)
    genvar g;
    generate
        for (g = 0; g < 8; g = g + 1) begin: prio_level_map
            assign priority_level[g] = priority_level_flat[g*2+1:g*2];
        end
    endgenerate

    // Calculate masks (combinatorial)
    always @(*) begin
        level0_mask = 0;
        level1_mask = 0;
        level2_mask = 0;
        level3_mask = 0;

        for (i = 0; i < 8; i = i + 1) begin
            case (priority_level[i])
                2'd0: level0_mask[i] = 1'b1;
                2'd1: level1_mask[i] = 1'b1;
                2'd2: level2_mask[i] = 1'b1;
                2'd3: level3_mask[i] = 1'b1;
            endcase
        end
    end

    // Combined FSM and input/mask registration logic
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            // Reset logic from both original blocks
            interrupts_r <= 8'd0;
            level0_mask_r <= 8'd0;
            level1_mask_r <= 8'd0;
            level2_mask_r <= 8'd0;
            level3_mask_r <= 8'd0;
            int_number <= 3'd0;
            handle_active <= 1'b0;
            current_level <= 2'd0;
            saved_context <= 32'd0;
        end else begin
            // Clock edge logic

            // Register high-fanout signals
            interrupts_r <= interrupts;
            level0_mask_r <= level0_mask;
            level1_mask_r <= level1_mask;
            level2_mask_r <= level2_mask;
            level3_mask_r <= level3_mask;

            // Main FSM logic (uses registered signals from previous cycle)
            if (!handle_active && |interrupts_r) begin
                if (|(interrupts_r & level3_mask_r)) begin
                    int_number <= find_first_set(interrupts_r & level3_mask_r);
                    current_level <= 2'd3;
                end else if (|(interrupts_r & level2_mask_r)) begin
                    int_number <= find_first_set(interrupts_r & level2_mask_r);
                    current_level <= 2'd2;
                end else if (|(interrupts_r & level1_mask_r)) begin
                    int_number <= find_first_set(interrupts_r & level1_mask_r);
                    current_level <= 2'd1;
                end else begin
                    int_number <= find_first_set(interrupts_r & level0_mask_r);
                    current_level <= 2'd0;
                end
                handle_active <= 1'b1;
                saved_context <= current_context; // current_context is not buffered, used directly
            end else if (handle_active && ack_done) begin
                handle_active <= 1'b0;
                // int_number, current_level, saved_context retain their values
            end
            // Implicit else: if neither condition is met, registered values retain their value.
        end
    end

    // Function implementation (combinatorial)
    function [2:0] find_first_set;
        input [7:0] bits;
        reg [2:0] result;
        begin
            // Transformed from casez to if-else if chain
            if (bits[0]) begin
                result = 3'd0;
            end else if (bits[1]) begin
                result = 3'd1;
            end else if (bits[2]) begin
                result = 3'd2;
            end else if (bits[3]) begin
                result = 3'd3;
            end else if (bits[4]) begin
                result = 3'd4;
            end else if (bits[5]) begin
                result = 3'd5;
            end else if (bits[6]) begin
                result = 3'd6;
            end else if (bits[7]) begin
                result = 3'd7;
            end else begin
                result = 3'd0; // Handles the case where bits is all zeros
            end
            find_first_set = result;
        end
    endfunction
endmodule