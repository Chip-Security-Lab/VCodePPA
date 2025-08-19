//SystemVerilog
module decoder_core #(
    parameter WIDTH = 4
)(
    input clk,
    input rst_n,
    input valid_in,
    output reg valid_out,
    input [1:0] addr,
    output reg [WIDTH-1:0] dec_out
);
    // Stage 1 registers
    reg [1:0] addr_stage1;
    reg valid_stage1;
    
    // Stage 2 registers
    reg [WIDTH-1:0] temp_stage2;
    reg valid_stage2;
    
    // Stage 3 registers
    reg [WIDTH-1:0] comp_stage3;
    reg valid_stage3;
    
    // Stage 1: Input registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= 2'b0;
            valid_stage1 <= 1'b0;
        end else begin
            addr_stage1 <= addr;
            valid_stage1 <= valid_in;
        end
    end
    
    // Stage 2: Temp calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            temp_stage2 <= {WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            temp_stage2 <= {2'b0, addr_stage1};
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Complement calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            comp_stage3 <= {WIDTH{1'b0}};
            valid_stage3 <= 1'b0;
        end else begin
            comp_stage3 <= ~temp_stage2 + 1'b1;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Stage 4: Final shift and output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dec_out <= {WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else begin
            dec_out <= 4'b0001 << comp_stage3[1:0];
            valid_out <= valid_stage3;
        end
    end
endmodule

module config_reg_decoder #(
    parameter REGISTERED_OUTPUT = 1
)(
    input clk,
    input rst_n,
    input valid_in,
    output valid_out,
    input [1:0] addr,
    output [3:0] dec_out
);
    wire [3:0] dec_comb;
    reg [3:0] dec_reg;
    wire valid_comb;
    
    decoder_core #(
        .WIDTH(4)
    ) u_decoder_core (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .valid_out(valid_comb),
        .addr(addr),
        .dec_out(dec_comb)
    );
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            dec_reg <= 4'b0;
        else if (valid_comb)
            dec_reg <= dec_comb;
    end
        
    assign dec_out = REGISTERED_OUTPUT ? dec_reg : dec_comb;
    assign valid_out = REGISTERED_OUTPUT ? valid_comb : valid_in;
endmodule