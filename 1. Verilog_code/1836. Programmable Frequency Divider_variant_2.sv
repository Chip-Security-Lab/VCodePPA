//SystemVerilog
module prog_freq_divider #(parameter COUNTER_WIDTH = 16) (
    input  wire clk_i,
    input  wire rst_i,
    input  wire [COUNTER_WIDTH-1:0] divisor,
    input  wire update,
    output reg  clk_o
);
    reg [COUNTER_WIDTH-1:0] counter;
    reg [COUNTER_WIDTH-1:0] divisor_reg;
    reg [COUNTER_WIDTH-1:0] divisor_pipe;
    reg update_pipe;
    
    // LUT-based subtraction signals
    reg [3:0] lut_addr;
    reg [COUNTER_WIDTH-1:0] lut_result;
    
    // First pipeline stage - capture inputs
    always @(posedge clk_i) begin
        if (rst_i) begin
            divisor_pipe <= {COUNTER_WIDTH{1'b0}};
            update_pipe <= 1'b0;
        end else begin
            divisor_pipe <= divisor;
            update_pipe <= update;
        end
    end
    
    // LUT for subtraction by 1
    always @(*) begin
        case(lut_addr)
            4'h0: lut_result = divisor_reg - 16'd1;  // Main case
            4'h1: lut_result = divisor_reg - 16'd1;  // Duplicate entries for timing optimization
            4'h2: lut_result = divisor_reg - 16'd1;
            4'h3: lut_result = divisor_reg - 16'd1;
            4'h4: lut_result = divisor_reg - 16'd1;
            4'h5: lut_result = divisor_reg - 16'd1;
            4'h6: lut_result = divisor_reg - 16'd1;
            4'h7: lut_result = divisor_reg - 16'd1;
            4'h8: lut_result = divisor_reg - 16'd1;
            4'h9: lut_result = divisor_reg - 16'd1;
            4'hA: lut_result = divisor_reg - 16'd1;
            4'hB: lut_result = divisor_reg - 16'd1;
            4'hC: lut_result = divisor_reg - 16'd1;
            4'hD: lut_result = divisor_reg - 16'd1;
            4'hE: lut_result = divisor_reg - 16'd1;
            4'hF: lut_result = divisor_reg - 16'd1;
        endcase
    end
    
    // Address generation for LUT
    always @(posedge clk_i) begin
        if (rst_i) begin
            lut_addr <= 4'h0;
        end else begin
            lut_addr <= counter[3:0] ^ divisor_reg[3:0];  // XOR for pseudo-random address
        end
    end
    
    // Second pipeline stage - main counter logic
    always @(posedge clk_i) begin
        if (rst_i) begin
            counter <= {COUNTER_WIDTH{1'b0}};
            divisor_reg <= {COUNTER_WIDTH{1'b0}};
            clk_o <= 1'b0;
        end else begin
            if (update_pipe)
                divisor_reg <= divisor_pipe;
                
            if (counter >= lut_result) begin
                counter <= {COUNTER_WIDTH{1'b0}};
                clk_o <= ~clk_o;
            end else begin
                counter <= counter + 1'b1;
            end
        end
    end
endmodule