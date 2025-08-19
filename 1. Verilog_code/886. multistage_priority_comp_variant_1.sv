//SystemVerilog
module priority_encoder #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] data_in,
    output reg [$clog2(WIDTH)-1:0] priority_out,
    output reg valid_out
);
    always @(*) begin
        valid_out = 0;
        priority_out = 0;
        for (integer i = WIDTH-1; i >= 0; i = i - 1) begin
            if (data_in[i]) begin
                valid_out = 1;
                priority_out = i[$clog2(WIDTH)-1:0];
            end
        end
    end
endmodule

module priority_stage #(
    parameter WIDTH = 16,
    parameter STAGE_ID = 0,
    parameter STAGES = 3
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] data_in,
    output reg [$clog2(WIDTH/STAGES)-1:0] priority_out,
    output reg valid_out
);
    localparam STAGE_WIDTH = WIDTH / STAGES;
    localparam START_BIT = STAGE_ID * STAGE_WIDTH;
    localparam END_BIT = START_BIT + STAGE_WIDTH - 1;
    
    wire [STAGE_WIDTH-1:0] stage_data;
    wire [$clog2(STAGE_WIDTH)-1:0] enc_priority;
    wire enc_valid;
    
    assign stage_data = data_in[END_BIT:START_BIT];
    
    priority_encoder #(
        .WIDTH(STAGE_WIDTH)
    ) encoder (
        .data_in(stage_data),
        .priority_out(enc_priority),
        .valid_out(enc_valid)
    );
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_out <= 0;
            valid_out <= 0;
        end else begin
            priority_out <= enc_priority;
            valid_out <= enc_valid;
        end
    end
endmodule

module priority_combiner #(
    parameter WIDTH = 16,
    parameter STAGES = 3
)(
    input clk,
    input rst_n,
    input [STAGES-1:0] valid_in,
    input [$clog2(WIDTH/STAGES)-1:0] priority_in [0:STAGES-1],
    output reg [$clog2(WIDTH)-1:0] priority_out
);
    wire [$clog2(STAGES)-1:0] stage_sel;
    wire [$clog2(WIDTH/STAGES)-1:0] stage_priority;
    
    priority_encoder #(
        .WIDTH(STAGES)
    ) stage_selector (
        .data_in(valid_in),
        .priority_out(stage_sel),
        .valid_out()
    );
    
    assign stage_priority = priority_in[stage_sel];
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_out <= 0;
        end else begin
            priority_out <= {stage_sel, stage_priority};
        end
    end
endmodule

module multistage_priority_comp #(
    parameter WIDTH = 16,
    parameter STAGES = 3
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] data_in,
    output [$clog2(WIDTH)-1:0] priority_out
);
    wire [STAGES-1:0] stage_valid;
    wire [$clog2(WIDTH/STAGES)-1:0] stage_priority [0:STAGES-1];

    genvar s;
    generate
        for (s = 0; s < STAGES; s = s + 1) begin : stage_gen
            priority_stage #(
                .WIDTH(WIDTH),
                .STAGE_ID(s),
                .STAGES(STAGES)
            ) stage_inst (
                .clk(clk),
                .rst_n(rst_n),
                .data_in(data_in),
                .priority_out(stage_priority[s]),
                .valid_out(stage_valid[s])
            );
        end
    endgenerate

    priority_combiner #(
        .WIDTH(WIDTH),
        .STAGES(STAGES)
    ) combiner_inst (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(stage_valid),
        .priority_in(stage_priority),
        .priority_out(priority_out)
    );
endmodule