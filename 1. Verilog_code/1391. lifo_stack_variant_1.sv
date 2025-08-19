//SystemVerilog
module lifo_stack #(parameter DW=8, DEPTH=8) (
    input clk, rst_n,
    input push, pop,
    input [DW-1:0] din,
    output [DW-1:0] dout,
    output full, empty
);
    // Memory and pointers
    reg [DW-1:0] mem [0:DEPTH-1];
    reg [2:0] ptr_stage1, ptr_stage2, ptr_stage3;
    
    // Pipeline control signals
    reg push_stage1, push_stage2;
    reg pop_stage1, pop_stage2;
    reg [DW-1:0] din_stage1, din_stage2;
    reg full_stage1, empty_stage1;
    reg full_stage2, empty_stage2;
    reg [DW-1:0] dout_reg;
    
    // Parallel prefix subtractor signals
    wire [2:0] subtractor_result;
    wire [2:0] operand_a = ptr_stage2;
    wire [2:0] operand_b = 3'b001; // Constant 1 for decrement
    wire [2:0] p_gen;  // Propagate signals
    wire [2:0] g_gen;  // Generate signals
    wire [2:0] p_prefix; // Prefix propagate signals
    wire [2:0] g_prefix; // Prefix generate signals
    
    // Parallel prefix subtractor implementation
    // Generate propagate and generate signals
    assign p_gen = operand_a ^ operand_b;
    assign g_gen = ~operand_a & operand_b;
    
    // Prefix tree for 3-bit subtractor
    // Level 1 - Group size 1
    assign p_prefix[0] = p_gen[0];
    assign g_prefix[0] = g_gen[0];
    
    // Level 2 - Group size 2
    assign p_prefix[1] = p_gen[1] & p_gen[0];
    assign g_prefix[1] = g_gen[1] | (p_gen[1] & g_gen[0]);
    
    // Level 3 - Group size 4
    assign p_prefix[2] = p_gen[2] & p_prefix[1];
    assign g_prefix[2] = g_gen[2] | (p_gen[2] & g_prefix[1]);
    
    // Sum computation
    assign subtractor_result[0] = p_gen[0] ^ g_gen[0];
    assign subtractor_result[1] = p_gen[1] ^ g_prefix[0];
    assign subtractor_result[2] = p_gen[2] ^ g_prefix[1];
    
    // Merged always block for all stage updates on the same clock edge
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            // Stage 1 reset
            push_stage1 <= 0;
            pop_stage1 <= 0;
            din_stage1 <= 0;
            ptr_stage1 <= 0;
            full_stage1 <= 0;
            empty_stage1 <= 1;
            
            // Stage 2 reset
            push_stage2 <= 0;
            pop_stage2 <= 0;
            din_stage2 <= 0;
            ptr_stage2 <= 0;
            full_stage2 <= 0;
            empty_stage2 <= 1;
            
            // Stage 3 reset
            ptr_stage3 <= 0;
            
            // Output reset
            dout_reg <= 0;
        end 
        else begin
            // Stage 1: Input capture and flag generation
            push_stage1 <= push;
            pop_stage1 <= pop;
            din_stage1 <= din;
            ptr_stage1 <= ptr_stage3;
            full_stage1 <= (ptr_stage3 == DEPTH);
            empty_stage1 <= (ptr_stage3 == 0);
            
            // Stage 2: Operation evaluation
            push_stage2 <= push_stage1;
            pop_stage2 <= pop_stage1;
            din_stage2 <= din_stage1;
            ptr_stage2 <= ptr_stage1;
            full_stage2 <= full_stage1;
            empty_stage2 <= empty_stage1;
            
            // Stage 3: Memory and pointer update
            case({push_stage2, pop_stage2})
                2'b10: begin
                    if(!full_stage2) begin
                        mem[ptr_stage2] <= din_stage2;
                        ptr_stage3 <= ptr_stage2 + 1;
                    end 
                    else begin
                        ptr_stage3 <= ptr_stage2;
                    end
                end
                2'b01: begin
                    if(!empty_stage2) begin
                        ptr_stage3 <= subtractor_result;
                    end 
                    else begin
                        ptr_stage3 <= ptr_stage2;
                    end
                end
                default: ptr_stage3 <= ptr_stage2;
            endcase
            
            // Output update
            dout_reg <= mem[subtractor_result];
        end
    end
    
    // Output assignments
    assign dout = dout_reg;
    assign full = full_stage2;
    assign empty = empty_stage2;
    
endmodule