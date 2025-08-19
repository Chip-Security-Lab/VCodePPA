//SystemVerilog
module rom_lut #(
    parameter OUT = 24,
    parameter SEL_WIDTH = 4
)(
    input clk,
    input rst_n,
    input [SEL_WIDTH-1:0] sel,
    output reg [OUT-1:0] value
);

    // Pipeline stage registers
    reg [SEL_WIDTH-1:0] sel_reg;
    reg [OUT-1:0] value_reg;
    
    // Carry lookahead subtractor signals
    wire [3:0] borrow;
    wire [3:0] diff;
    wire [3:0] sel_sub;
    
    // Generate borrow signals
    assign borrow[0] = 1'b0;
    assign borrow[1] = (sel_reg[0] & ~sel_reg[1]) | borrow[0];
    assign borrow[2] = (sel_reg[1] & ~sel_reg[2]) | borrow[1];
    assign borrow[3] = (sel_reg[2] & ~sel_reg[3]) | borrow[2];
    
    // Generate difference signals
    assign diff[0] = sel_reg[0] ^ borrow[0];
    assign diff[1] = sel_reg[1] ^ borrow[1];
    assign diff[2] = sel_reg[2] ^ borrow[2];
    assign diff[3] = sel_reg[3] ^ borrow[3];
    
    assign sel_sub = diff;

    // Stage 1: Input registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sel_reg <= {SEL_WIDTH{1'b0}};
        end else begin
            sel_reg <= sel;
        end
    end

    // Stage 2: LUT computation with carry lookahead subtractor
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            value_reg <= {OUT{1'b0}};
        end else begin
            case(sel_sub)
                4'h0: value_reg <= 24'h000001;
                4'h1: value_reg <= 24'h000002;
                4'h2: value_reg <= 24'h000004;
                4'h3: value_reg <= 24'h000008;
                4'h4: value_reg <= 24'h000010;
                4'h5: value_reg <= 24'h000020;
                4'h6: value_reg <= 24'h000040;
                4'h7: value_reg <= 24'h000080;
                4'h8: value_reg <= 24'h000100;
                4'h9: value_reg <= 24'h000200;
                4'hA: value_reg <= 24'h000400;
                4'hB: value_reg <= 24'h000800;
                4'hC: value_reg <= 24'h001000;
                4'hD: value_reg <= 24'h002000;
                4'hE: value_reg <= 24'h004000;
                4'hF: value_reg <= 24'h008000;
                default: value_reg <= {OUT{1'b0}};
            endcase
        end
    end

    // Stage 3: Output registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            value <= {OUT{1'b0}};
        end else begin
            value <= value_reg;
        end
    end

endmodule