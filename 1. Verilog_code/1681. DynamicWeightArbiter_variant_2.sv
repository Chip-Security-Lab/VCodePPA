//SystemVerilog
// Top Level Module
module DynamicWeightArbiter #(parameter DW=8) (
    input clk, rst,
    input [4*DW-1:0] dyn_weights,
    input [3:0] req,
    output reg [3:0] grant
);

    wire [DW-1:0] weight_array [0:3];
    wire [DW-1:0] acc_weights [0:3];
    wire [DW-1:0] acc_weights_pipe [0:3];
    reg [3:0] req_pipe;
    wire [3:0] grant_pipe;

    // Extract individual weights
    genvar g;
    generate
        for (g = 0; g < 4; g = g + 1) begin: weight_extract
            assign weight_array[g] = dyn_weights[g*DW +: DW];
        end
    endgenerate

    // Instantiate weight accumulators
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin: acc_gen
            WeightAccumulator #(.DW(DW)) weight_acc (
                .clk(clk),
                .rst(rst),
                .weight_in(weight_array[i]),
                .acc_weight(acc_weights[i]),
                .acc_weight_pipe(acc_weights_pipe[i])
            );
        end
    endgenerate

    // Request pipeline register
    always @(posedge clk) begin
        if(rst)
            req_pipe <= 0;
        else
            req_pipe <= req;
    end

    // Instantiate weight comparator
    WeightComparator #(.DW(DW)) weight_comp (
        .acc_weights_pipe(acc_weights_pipe),
        .req_pipe(req_pipe),
        .grant_pipe(grant_pipe)
    );

    // Final grant pipeline register
    always @(posedge clk) begin
        if(rst)
            grant <= 0;
        else
            grant <= grant_pipe;
    end

endmodule

// Weight Accumulator Module
module WeightAccumulator #(parameter DW=8) (
    input clk, rst,
    input [DW-1:0] weight_in,
    output reg [DW-1:0] acc_weight,
    output reg [DW-1:0] acc_weight_pipe
);

    always @(posedge clk) begin
        if(rst) begin
            acc_weight <= 0;
            acc_weight_pipe <= 0;
        end else begin
            acc_weight <= acc_weight + weight_in;
            acc_weight_pipe <= acc_weight;
        end
    end

endmodule

// Weight Comparator Module
module WeightComparator #(parameter DW=8) (
    input [DW-1:0] acc_weights_pipe [0:3],
    input [3:0] req_pipe,
    output reg [3:0] grant_pipe
);

    wire [1:0] max_idx;
    wire [DW-1:0] max_val;

    // Find maximum weight and its index
    always @(*) begin
        case ({acc_weights_pipe[0] > acc_weights_pipe[1], 
               acc_weights_pipe[0] > acc_weights_pipe[2],
               acc_weights_pipe[0] > acc_weights_pipe[3],
               acc_weights_pipe[1] > acc_weights_pipe[2],
               acc_weights_pipe[1] > acc_weights_pipe[3],
               acc_weights_pipe[2] > acc_weights_pipe[3]})
            6'b111111: grant_pipe = 4'b0001 & req_pipe;
            6'b001111: grant_pipe = 4'b0010 & req_pipe;
            6'b000011: grant_pipe = 4'b0100 & req_pipe;
            default:   grant_pipe = 4'b1000 & req_pipe;
        endcase
    end

endmodule