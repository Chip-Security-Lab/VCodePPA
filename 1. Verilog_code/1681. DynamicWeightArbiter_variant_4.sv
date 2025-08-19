//SystemVerilog
// Top-level module
module DynamicWeightArbiter #(parameter DW=8) (
    input clk, rst,
    input [4*DW-1:0] dyn_weights,
    input [3:0] req,
    output [3:0] grant
);

    // Internal signals
    wire [DW-1:0] weight_array [0:3];
    wire [3:0] grant_comb;
    wire [DW-1:0] acc_weights [0:3];
    wire [DW-1:0] next_acc_weights [0:3];
    
    // Instantiate combinational logic module
    DynamicWeightArbiterComb #(
        .DW(DW)
    ) comb_logic (
        .dyn_weights(dyn_weights),
        .acc_weights(acc_weights),
        .req(req),
        .weight_array(weight_array),
        .next_acc_weights(next_acc_weights),
        .grant_comb(grant_comb)
    );
    
    // Instantiate sequential logic module
    DynamicWeightArbiterSeq #(
        .DW(DW)
    ) seq_logic (
        .clk(clk),
        .rst(rst),
        .next_acc_weights(next_acc_weights),
        .grant_comb(grant_comb),
        .acc_weights(acc_weights),
        .grant(grant)
    );

endmodule

// Combinational logic module
module DynamicWeightArbiterComb #(parameter DW=8) (
    input [4*DW-1:0] dyn_weights,
    input [DW-1:0] acc_weights [0:3],
    input [3:0] req,
    output [DW-1:0] weight_array [0:3],
    output [DW-1:0] next_acc_weights [0:3],
    output [3:0] grant_comb
);

    // Extract individual weights - combinational logic
    assign weight_array[0] = dyn_weights[0*DW +: DW];
    assign weight_array[1] = dyn_weights[1*DW +: DW];
    assign weight_array[2] = dyn_weights[2*DW +: DW];
    assign weight_array[3] = dyn_weights[3*DW +: DW];

    // Next state calculation - combinational logic
    assign next_acc_weights[0] = acc_weights[0] + weight_array[0];
    assign next_acc_weights[1] = acc_weights[1] + weight_array[1];
    assign next_acc_weights[2] = acc_weights[2] + weight_array[2];
    assign next_acc_weights[3] = acc_weights[3] + weight_array[3];

    // Grant calculation - combinational logic
    assign grant_comb = (acc_weights[0] > acc_weights[1] && acc_weights[0] > acc_weights[2] && acc_weights[0] > acc_weights[3]) ? (4'b0001 & req) :
                       (acc_weights[1] > acc_weights[0] && acc_weights[1] > acc_weights[2] && acc_weights[1] > acc_weights[3]) ? (4'b0010 & req) :
                       (acc_weights[2] > acc_weights[0] && acc_weights[2] > acc_weights[1] && acc_weights[2] > acc_weights[3]) ? (4'b0100 & req) :
                       (4'b1000 & req);

endmodule

// Sequential logic module
module DynamicWeightArbiterSeq #(parameter DW=8) (
    input clk, rst,
    input [DW-1:0] next_acc_weights [0:3],
    input [3:0] grant_comb,
    output reg [DW-1:0] acc_weights [0:3],
    output reg [3:0] grant
);

    // Sequential logic
    always @(posedge clk) begin
        if(rst) begin
            acc_weights[0] <= 0;
            acc_weights[1] <= 0;
            acc_weights[2] <= 0;
            acc_weights[3] <= 0;
            grant <= 0;
        end else begin
            acc_weights[0] <= next_acc_weights[0];
            acc_weights[1] <= next_acc_weights[1];
            acc_weights[2] <= next_acc_weights[2];
            acc_weights[3] <= next_acc_weights[3];
            grant <= grant_comb;
        end
    end

endmodule