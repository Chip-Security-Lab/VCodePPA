//SystemVerilog
module rr_async_icmu (
    input clk, // Added clock input for register buffering
    input rst,
    input [7:0] interrupt_in,
    input ctx_save_done,
    output [7:0] int_grant,
    output [2:0] int_vector,
    output context_save_req
);

    // Internal state register
    reg [2:0] last_served;

    // Pipelining registers for buffering high-fanout/critical path signals
    reg [7:0] masked_ints_r;
    reg [7:0] int_grant_r;
    reg [2:0] int_vector_r;
    reg context_save_req_r;

    // Wires for combinational logic results before registering
    wire [7:0] next_masked_ints;
    wire next_context_save_req;
    wire [7:0] next_int_grant;
    wire [2:0] next_int_vector;

    // Combinational logic stage 1: Calculate masked_ints and context_save_req
    // Based on current inputs
    assign next_masked_ints = interrupt_in; // Original code assigned interrupt_in directly
    assign next_context_save_req = |next_masked_ints;

    // Combinational logic stage 2: Calculate next_int_grant
    // Uses registered masked_ints (from previous clock cycle) and last_served
    assign next_int_grant = select_next(masked_ints_r, last_served);

    // Combinational logic stage 3: Calculate next_int_vector
    // Uses registered int_grant (from previous clock cycle)
    assign next_int_vector = encode_vec(int_grant_r);

    // Sequential logic: Pipelining registers
    // These registers capture the results of the combinational stages on the clock edge
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            masked_ints_r <= 8'b0;
            int_grant_r <= 8'b0;
            int_vector_r <= 3'b0;
            context_save_req_r <= 1'b0;
        end else begin
            masked_ints_r <= next_masked_ints;       // Registering masked_ints
            int_grant_r <= next_int_grant;           // Registering the result of select_next
            int_vector_r <= next_int_vector;         // Registering the result of encode_vec
            context_save_req_r <= next_context_save_req; // Registering context_save_req
        end
    end

    // last_served register update based on ctx_save_done
    // Uses the registered int_vector value
    always @(posedge ctx_save_done or posedge rst) begin
         if (rst) last_served <= 3'b0;
         else last_served <= int_vector_r; // Update with registered vector
    end

    // Assign registered values to module outputs
    assign int_grant = int_grant_r;
    assign int_vector = int_vector_r;
    assign context_save_req = context_save_req_r;

    // Functions remain combinational logic descriptions
    // Internal function variables like 'mask' and 'high_result' are not buffered at the module level

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

            // Create mask using conditional assignment
            for (i = 0; i < 8; i = i + 1) begin
                mask[i] = (i > last);
            end

            // Find higher priority interrupts using conditional assignment
            for (i = 7; i >= 0; i = i - 1) begin
                high_result[i] = ints[i] && mask[i];
            end

            // Find any interrupt using conditional assignment
            for (i = 7; i >= 0; i = i - 1) begin
                any_result[i] = ints[i];
            end

            // Select result using ternary operator (functionally equivalent to flat if-else)
            select_next = (|high_result) ? high_result : any_result;
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

    // find_first function is not used in the original logic, keeping it as is.
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