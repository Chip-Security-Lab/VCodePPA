//SystemVerilog
module dual_rail_encoder #(parameter WIDTH = 4) (
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire [WIDTH-1:0]       data_in,
    input  wire                   valid_in,
    output wire [2*WIDTH-1:0]     dual_rail_out
);

    // Stage 1: Input register stage (pipelining)
    reg [WIDTH-1:0]      data_in_reg1;
    reg                  valid_in_reg1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg1   <= {WIDTH{1'b0}};
            valid_in_reg1  <= 1'b0;
        end else begin
            data_in_reg1   <= data_in;
            valid_in_reg1  <= valid_in;
        end
    end

    // Stage 2: Pipeline register for data and valid
    reg [WIDTH-1:0]      data_in_reg2;
    reg                  valid_in_reg2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg2   <= {WIDTH{1'b0}};
            valid_in_reg2  <= 1'b0;
        end else begin
            data_in_reg2   <= data_in_reg1;
            valid_in_reg2  <= valid_in_reg1;
        end
    end

    // Stage 3: Dual-rail encode combinational logic (optimized)
    wire [2*WIDTH-1:0]   dual_rail_encoded_comb;

    assign dual_rail_encoded_comb = { 
        {WIDTH{valid_in_reg2}} & {~data_in_reg2, data_in_reg2}
    };

    // Stage 4: Pipeline register for dual-rail encode output and valid
    reg [2*WIDTH-1:0]    dual_rail_encoded_reg3;
    reg                  valid_in_reg3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dual_rail_encoded_reg3 <= {2*WIDTH{1'b0}};
            valid_in_reg3          <= 1'b0;
        end else begin
            dual_rail_encoded_reg3 <= dual_rail_encoded_comb;
            valid_in_reg3          <= valid_in_reg2;
        end
    end

    // Stage 5: Final output register stage (pipelining, optimized)
    reg [2*WIDTH-1:0]    dual_rail_out_reg4;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dual_rail_out_reg4 <= {2*WIDTH{1'b0}};
        end else begin
            dual_rail_out_reg4 <= valid_in_reg3 ? dual_rail_encoded_reg3 : {2*WIDTH{1'b0}};
        end
    end

    // Output assignment
    assign dual_rail_out = dual_rail_out_reg4;

endmodule