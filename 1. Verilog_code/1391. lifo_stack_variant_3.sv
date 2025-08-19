//SystemVerilog
module lifo_stack #(parameter DW=8, DEPTH=8) (
    input clk, rst_n,
    input push, pop,
    input [DW-1:0] din,
    output reg [DW-1:0] dout,
    output reg full, empty
);
    // Memory array
    reg [DW-1:0] mem [0:DEPTH-1];
    reg [2:0] ptr;
    
    // Pre-computed values for combinational logic
    wire [2:0] next_ptr_push = ptr + 3'b001;
    
    // Using two's complement addition for subtraction
    wire [2:0] ptr_complement = ~ptr + 3'b001; // Two's complement of ptr
    wire [2:0] next_ptr_pop = ptr + 3'b111;    // Adding -1 (3'b111 is -1 in 3-bit two's complement)
    
    wire next_full = (next_ptr_push == DEPTH);
    wire next_empty = (next_ptr_pop == 0);
    
    // Registered outputs instead of combinational
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            full <= 0;
            empty <= 1;
            dout <= {DW{1'b0}};
        end else begin
            full <= (push && !pop && next_full) || (full && !(pop && !push));
            empty <= (pop && !push && next_empty) || (empty && !(push && !pop));
            
            if(!empty || push)
                // Using two's complement for ptr-1 calculation
                dout <= (push && empty) ? din : mem[ptr + 3'b111];
        end
    end
    
    // Main pointer and memory control logic
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            ptr <= 0;
        end else begin
            case({push,pop})
                2'b10: if(!full) begin
                    mem[ptr] <= din;
                    ptr <= next_ptr_push;
                end
                2'b01: if(!empty) begin
                    ptr <= next_ptr_pop;
                end
                2'b11: begin
                    // Push and pop simultaneously - implement as pop then push
                    // Using two's complement for next_ptr_pop calculation
                    mem[ptr + 3'b111] <= din;
                end
                default: ; // No action
            endcase
        end
    end
endmodule