//SystemVerilog
module key_expansion #(parameter KEY_WIDTH = 32, EXPANDED_WIDTH = 128) (
    input wire clk, rst_n,
    input wire key_load,
    input wire [KEY_WIDTH-1:0] key_in,
    output reg [EXPANDED_WIDTH-1:0] expanded_key,
    output reg key_ready
);
    // State and key registers
    reg [2:0] stage;
    reg [KEY_WIDTH-1:0] key_reg;
    
    // Pipeline registers to break down the complex combinational path
    reg [KEY_WIDTH-1:0] rotated_key;
    reg [KEY_WIDTH-1:0] constant_mask;
    reg [KEY_WIDTH-1:0] expansion_temp;
    
    // Additional pipeline registers for optimization
    reg [KEY_WIDTH-1:0] rotated_key_stage1;
    reg [KEY_WIDTH-1:0] constant_mask_stage1;
    reg [KEY_WIDTH-1:0] rotated_key_stage2;
    reg [KEY_WIDTH-1:0] constant_mask_stage2;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            stage <= 0;
            key_ready <= 0;
            expanded_key <= 0;
            rotated_key <= 0;
            constant_mask <= 0;
            expansion_temp <= 0;
            rotated_key_stage1 <= 0;
            constant_mask_stage1 <= 0;
            rotated_key_stage2 <= 0;
            constant_mask_stage2 <= 0;
        end else if (key_load) begin
            key_reg <= key_in;
            stage <= 1;
            key_ready <= 0;
        end else if (stage > 0 && stage < 8) begin
            case (stage)
                // Pipeline stage 1: Calculate rotation only
                1: begin
                    rotated_key <= {key_reg[KEY_WIDTH-9:0], key_reg[KEY_WIDTH-1:KEY_WIDTH-8]};
                    constant_mask <= {8'h01 << (1-1), 24'h0};
                    stage <= stage + 1;
                end
                
                // Pipeline stage 2: Register intermediate values
                2: begin
                    rotated_key_stage1 <= rotated_key;
                    constant_mask_stage1 <= constant_mask;
                    stage <= stage + 1;
                end
                
                // Pipeline stage 3: Perform XOR operations
                3: begin
                    expansion_temp <= key_reg ^ rotated_key_stage1 ^ constant_mask_stage1;
                    stage <= stage + 1;
                end
                
                // Pipeline stage 4: Store the result
                4: begin
                    expanded_key[0 +: KEY_WIDTH] <= expansion_temp;
                    // Prepare for next round
                    rotated_key <= {key_reg[KEY_WIDTH-9:0], key_reg[KEY_WIDTH-1:KEY_WIDTH-8]};
                    constant_mask <= {8'h01 << (2-1), 24'h0};
                    stage <= stage + 1;
                end
                
                // Pipeline stage 5: Register intermediate values for second round
                5: begin
                    rotated_key_stage2 <= rotated_key;
                    constant_mask_stage2 <= constant_mask;
                    stage <= stage + 1;
                end
                
                // Pipeline stage 6: Calculate second round
                6: begin
                    expansion_temp <= key_reg ^ rotated_key_stage2 ^ constant_mask_stage2;
                    stage <= stage + 1;
                end
                
                // Pipeline stage 7: Store second round and calculate third and fourth round
                7: begin
                    expanded_key[KEY_WIDTH +: KEY_WIDTH] <= expansion_temp;
                    
                    // Pipeline the third round calculation
                    rotated_key <= {key_reg[KEY_WIDTH-9:0], key_reg[KEY_WIDTH-1:KEY_WIDTH-8]};
                    constant_mask <= {8'h01 << (3-1), 24'h0};
                    
                    // Break down the long path for the third round
                    expanded_key[2*KEY_WIDTH +: KEY_WIDTH] <= 
                        key_reg ^ rotated_key_stage2 ^ {8'h01 << (3-1), 24'h0};
                    
                    // Break down the long path for the fourth round
                    expanded_key[3*KEY_WIDTH +: KEY_WIDTH] <= 
                        key_reg ^ rotated_key_stage2 ^ {8'h01 << 3, 24'h0};
                    
                    key_ready <= 1;
                    stage <= 0;
                end
            endcase
        end
    end
endmodule