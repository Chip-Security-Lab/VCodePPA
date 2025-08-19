//SystemVerilog
// Priority Encoder Core Module
module PriorityEncoderCore #(
    parameter N = 16
)(
    input [N-1:0] req,
    output reg [$clog2(N)-1:0] encoded_pos
);
    integer i;
    always @(*) begin
        encoded_pos = 0;
        for (i = N-1; i >= 0; i = i - 1)
            if (req[i]) encoded_pos = i;
    end
endmodule

// Data Selection Control Module
module DataSelectControl #(
    parameter N = 16
)(
    input [N-1:0] req,
    input [$clog2(N)-1:0] encoded_pos,
    output reg [N-1:0] select_mask
);
    always @(*) begin
        select_mask = 1'b1 << encoded_pos;
    end
endmodule

// Data Output Module
module DataOutput #(
    parameter W = 8,
    parameter N = 16
)(
    input [W-1:0] data [0:N-1],
    input [N-1:0] select_mask,
    output reg [W-1:0] selected_data
);
    integer i;
    always @(*) begin
        selected_data = '0;
        for (i = 0; i < N; i = i + 1)
            if (select_mask[i]) selected_data = data[i];
    end
endmodule

// Top Level Module
module MuxBinaryEnc #(
    parameter W = 8,
    parameter N = 16
)(
    input [N-1:0] req,
    input [W-1:0] data [0:N-1],
    output [W-1:0] grant_data
);
    wire [$clog2(N)-1:0] encoded_pos;
    wire [N-1:0] select_mask;

    PriorityEncoderCore #(
        .N(N)
    ) pe_core (
        .req(req),
        .encoded_pos(encoded_pos)
    );

    DataSelectControl #(
        .N(N)
    ) ds_ctrl (
        .req(req),
        .encoded_pos(encoded_pos),
        .select_mask(select_mask)
    );

    DataOutput #(
        .W(W),
        .N(N)
    ) data_out (
        .data(data),
        .select_mask(select_mask),
        .selected_data(grant_data)
    );
endmodule