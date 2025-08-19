module cam_pipelined #(parameter WIDTH=8, DEPTH=256)(
    input clk,
    input [WIDTH-1:0] data_in,
    output reg [$clog2(DEPTH)-1:0] match_addr,
    output reg match_valid
);

    wire [DEPTH-1:0] stage1_hits;
    wire [DEPTH-1:0] match_mask;
    wire [$clog2(DEPTH)-1:0] priority_encoder_out;

    // Submodule instances
    cam_compare #(.WIDTH(WIDTH), .DEPTH(DEPTH)) u_compare(
        .clk(clk),
        .data_in(data_in),
        .stage1_hits(stage1_hits)
    );

    cam_priority_encoder #(.DEPTH(DEPTH)) u_encoder(
        .stage1_hits(stage1_hits),
        .match_mask(match_mask),
        .priority_encoder_out(priority_encoder_out)
    );

    // Output stage
    always @(posedge clk) begin
        match_valid <= |stage1_hits;
        match_addr <= priority_encoder_out;
    end
endmodule

module cam_compare #(parameter WIDTH=8, DEPTH=256)(
    input clk,
    input [WIDTH-1:0] data_in,
    output reg [DEPTH-1:0] stage1_hits
);
    reg [WIDTH-1:0] entries [0:DEPTH-1];
    
    genvar k;
    generate
        for(k=0; k<DEPTH; k=k+1) begin : COMPARE
            always @(posedge clk) begin
                stage1_hits[k] <= (entries[k] == data_in);
            end
        end
    endgenerate
endmodule

module cam_priority_encoder #(parameter DEPTH=256)(
    input [DEPTH-1:0] stage1_hits,
    output [DEPTH-1:0] match_mask,
    output [$clog2(DEPTH)-1:0] priority_encoder_out
);
    assign match_mask = stage1_hits & (~(stage1_hits - 1));
    
    genvar k;
    generate
        for(k=0; k<DEPTH; k=k+1) begin : ENCODER
            assign priority_encoder_out = match_mask[k] ? k[$clog2(DEPTH)-1:0] : 'b0;
        end
    endgenerate
endmodule