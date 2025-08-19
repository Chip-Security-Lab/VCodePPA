//SystemVerilog
module triangle_sine_approx(
    input clk,
    input reset,
    output reg [7:0] sine_out
);
    // Stage 1: Triangle wave generation
    reg [7:0] triangle;
    reg up_down;
    reg valid_stage1;
    reg [7:0] triangle_stage1;
    
    // Skip Carry Adder signals
    wire [7:0] sum;
    wire [7:0] p, g; // Propagate and Generate signals
    wire [8:0] c;    // Carry signals (extra bit for final carry)
    
    // Generate propagate and generate signals for Skip Carry Adder
    assign p = up_down ? {8{1'b1}} : triangle;
    assign g = up_down ? triangle : 8'd0;
    
    // Skip carry generation logic - 2-bit skip blocks
    assign c[0] = 1'b0;
    assign c[2] = g[0] | (p[0] & g[1]) | (p[0] & p[1] & c[0]);
    assign c[4] = g[2] | (p[2] & g[3]) | (p[2] & p[3] & c[2]);
    assign c[6] = g[4] | (p[4] & g[5]) | (p[4] & p[5] & c[4]);
    assign c[8] = g[6] | (p[6] & g[7]) | (p[6] & p[7] & c[6]);
    
    // Carry propagation within blocks
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & c[2]);
    assign c[5] = g[4] | (p[4] & c[4]);
    assign c[7] = g[6] | (p[6] & c[6]);
    
    // Sum computation
    assign sum[0] = p[0] ^ g[0] ^ c[0];
    assign sum[1] = p[1] ^ g[1] ^ c[1];
    assign sum[2] = p[2] ^ g[2] ^ c[2];
    assign sum[3] = p[3] ^ g[3] ^ c[3];
    assign sum[4] = p[4] ^ g[4] ^ c[4];
    assign sum[5] = p[5] ^ g[5] ^ c[5];
    assign sum[6] = p[6] ^ g[6] ^ c[6];
    assign sum[7] = p[7] ^ g[7] ^ c[7];
    
    // Generate triangle wave
    always @(posedge clk) begin
        if (reset) begin
            triangle <= 8'd0;
            up_down <= 1'b1;
            valid_stage1 <= 1'b0;
        end else begin
            valid_stage1 <= 1'b1;
            
            if (up_down) begin
                if (triangle == 8'd255)
                    up_down <= 1'b0;
                else
                    triangle <= sum;
            end else begin
                if (triangle == 8'd0)
                    up_down <= 1'b1;
                else
                    triangle <= sum;
            end
            
            triangle_stage1 <= triangle;
        end
    end
    
    // Stage 2: Comparison and category determination
    reg [1:0] category_stage2;
    reg valid_stage2;
    reg [7:0] triangle_stage2;
    
    always @(posedge clk) begin
        if (reset) begin
            category_stage2 <= 2'd0;
            valid_stage2 <= 1'b0;
            triangle_stage2 <= 8'd0;
        end else begin
            valid_stage2 <= valid_stage1;
            triangle_stage2 <= triangle_stage1;
            
            if (triangle_stage1 < 8'd64)
                category_stage2 <= 2'd0;
            else if (triangle_stage1 < 8'd192)
                category_stage2 <= 2'd1;
            else
                category_stage2 <= 2'd2;
        end
    end
    
    // Stage 3: Computation stage with barrel shifter implementation
    reg valid_stage3;
    reg [7:0] sine_value_stage3;
    
    // Barrel shifter implementation for right shift by 1 or 2
    wire [7:0] shift_by_1, shift_by_2;
    
    // Shift by 1 implementation (right shift)
    assign shift_by_1[7] = 1'b0;
    assign shift_by_1[6:0] = triangle_stage2[7:1];
    
    // Shift by 2 implementation (right shift)
    assign shift_by_2[7] = 1'b0;
    assign shift_by_2[6] = 1'b0;
    assign shift_by_2[5:0] = triangle_stage2[7:2];
    
    always @(posedge clk) begin
        if (reset) begin
            valid_stage3 <= 1'b0;
            sine_value_stage3 <= 8'd0;
        end else begin
            valid_stage3 <= valid_stage2;
            
            case (category_stage2)
                2'd0: sine_value_stage3 <= 8'd64 + shift_by_1;
                2'd1: sine_value_stage3 <= 8'd96 + shift_by_1;
                2'd2: sine_value_stage3 <= 8'd192 + shift_by_2;
                default: sine_value_stage3 <= 8'd0;
            endcase
        end
    end
    
    // Stage 4: Output stage
    always @(posedge clk) begin
        if (reset) begin
            sine_out <= 8'd0;
        end else if (valid_stage3) begin
            sine_out <= sine_value_stage3;
        end
    end
endmodule