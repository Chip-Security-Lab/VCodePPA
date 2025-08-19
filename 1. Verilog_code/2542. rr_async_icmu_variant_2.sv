//SystemVerilog
module rr_sync_valid_ready (
    input clk,
    input rst,
    input [7:0] interrupt_in,
    input ready,
    output reg [7:0] int_grant,
    output reg [2:0] int_vector,
    output reg valid
);

    // State register for last served interrupt vector
    reg [2:0] last_served;

    // Pipelining registers for high-fanout signals and critical path
    reg [7:0] masked_ints_reg; // Registered version of interrupt_in (or masked_ints)
    reg valid_reg;             // Registered valid signal
    reg [7:0] int_grant_reg;   // Registered output of select_next
    reg [2:0] int_vector_reg;  // Registered output of encode_vec

    // Combinational wires for calculating next values
    wire valid_comb;
    wire [7:0] int_grant_comb;
    wire [2:0] int_vector_comb;

    // Register the input interrupt_in to break fanout path
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            masked_ints_reg <= 8'b0;
        end else begin
            masked_ints_reg <= interrupt_in;
        end
    end

    // Combinational logic based on registered inputs and state
    assign valid_comb = |masked_ints_reg; // valid based on registered interrupt_in
    assign int_grant_comb = select_next(masked_ints_reg, last_served); // grant based on registered interrupt_in and last_served
    assign int_vector_comb = encode_vec(int_grant_comb); // vector based on combinational grant

    // Register the outputs of the combinational logic stages
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            valid_reg <= 1'b0;
            int_grant_reg <= 8'b0;
            int_vector_reg <= 3'b0;
        end else begin
            valid_reg <= valid_comb;       // Register valid
            int_grant_reg <= int_grant_comb; // Register int_grant
            int_vector_reg <= int_vector_comb; // Register int_vector
        end
    end

    // Sequential logic for state update (last_served)
    // Update last_served only on successful handshake (registered valid && input ready)
    // Update value is the registered vector from the previous cycle
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            last_served <= 3'b0;
        end else begin
            // Handshake uses the registered valid and the current ready input
            // Update uses the registered vector
            if (valid_reg && ready) begin
                last_served <= int_vector_reg;
            end
        end
    end

    // Assign registered outputs to the module ports
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            valid <= 1'b0;
            int_grant <= 8'b0;
            int_vector <= 3'b0;
        end else begin
            valid <= valid_reg;
            int_grant <= int_grant_reg;
            int_vector <= int_vector_reg;
        end
    end


    // Functions remain the same - they are pure combinational logic
    function [7:0] select_next;
        input [7:0] ints;
        input [2:0] last;
        reg [7:0] mask;
        reg [7:0] high_result;
        reg [7:0] any_result;
        integer i;
        begin
            mask = 0;
            high_result = 0;
            any_result = 0;

            // Create mask for priorities higher than last_served
            for (i = 0; i < 8; i = i + 1) begin
                if (i > last) mask[i] = 1'b1;
            end

            // Find higher priority interrupts that are set
            for (i = 7; i >= 0; i = i - 1) begin
                if (ints[i] && mask[i]) high_result[i] = 1'b1;
            end

            // Find any interrupt that is set
            for (i = 7; i >= 0; i = i - 1) begin
                if (ints[i]) any_result[i] = 1'b1;
            end

            // Select result: higher priority if any, otherwise any interrupt
            if (|high_result)
                select_next = high_result;
            else
                select_next = any_result;
        end
    endfunction

    function [2:0] encode_vec;
        input [7:0] grant;
        begin
            casez(grant)
                8'b???????1: encode_vec = 3'd0;
                8'b??????10: encode_vec = 3'd1;
                8'b?????100: encode_vec = 3'd2;
                8'b????1000: encode_vec = 3'd3;
                8'b???10000: encode_vec = 3'd4;
                8'b??100000: encode_vec = 3'd5;
                8'b?1000000: encode_vec = 3'd6;
                8'b10000000: encode_vec = 3'd7;
                default: encode_vec = 3'd0;
            endcase
        end
    endfunction

    // Function find_first is not used in the module logic
    function [2:0] find_first;
        input [7:0] val;
        begin
            casez(val)
                8'b???????1: find_first = 3'd0;
                8'b??????10: find_first = 3'd1;
                8'b?????100: find_first = 3'd2;
                8'b????1000: find_first = 3'd3;
                8'b???10000: find_first = 3'd4;
                8'b??100000: find_first = 3'd5;
                8'b?1000000: find_first = 3'd6;
                8'b10000000: find_first = 3'd7;
                default: find_first = 3'd0;
            endcase
        end
    endfunction

endmodule