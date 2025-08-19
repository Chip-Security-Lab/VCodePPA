//SystemVerilog
module PrioArbMux #(
    parameter DW = 4
) (
    input  wire [3:0]        req,
    input  wire              en,
    output reg  [1:0]        grant,
    output wire [DW-1:0]     data
);

    // -----------------------------------------------------------------------------
    // Stage 1: Request Buffer Register (Fanin/Fanout Buffering)
    // -----------------------------------------------------------------------------
    reg [3:0] req_buf_stage1;
    reg [3:0] req_buf_stage2;

    always @(posedge en) begin : req_buffer_stage1
        req_buf_stage1 <= req;
    end

    always @(posedge en) begin : req_buffer_stage2
        req_buf_stage2 <= req_buf_stage1;
    end

    // -----------------------------------------------------------------------------
    // Stage 2: Request Priority Encoding (Combinational Using Buffered req)
    // -----------------------------------------------------------------------------
    reg [1:0] prio_encoded_comb;

    always @* begin : prio_encode_stage
        if (req_buf_stage2[3])       prio_encoded_comb = 2'b11;
        else if (req_buf_stage2[2])  prio_encoded_comb = 2'b10;
        else if (req_buf_stage2[1])  prio_encoded_comb = 2'b01;
        else                        prio_encoded_comb = 2'b00;
    end

    // -----------------------------------------------------------------------------
    // Stage 3: Priority Code Buffer Register (Fanout Buffering)
    // -----------------------------------------------------------------------------
    reg [1:0] prio_encoded_buf_stage1;
    reg [1:0] prio_encoded_buf_stage2;

    always @(posedge en) begin : prio_encoded_buffer_stage1
        prio_encoded_buf_stage1 <= prio_encoded_comb;
    end

    always @(posedge en) begin : prio_encoded_buffer_stage2
        prio_encoded_buf_stage2 <= prio_encoded_buf_stage1;
    end

    // -----------------------------------------------------------------------------
    // Stage 4: Grant Output Register (Synchronous)
    // -----------------------------------------------------------------------------
    always @(posedge en) begin : grant_output_stage
        if (en)
            grant <= prio_encoded_buf_stage2;
        else
            grant <= 2'b00;
    end

    // -----------------------------------------------------------------------------
    // Stage 5: Data Output Construction (Combinational)
    // -----------------------------------------------------------------------------
    assign data = {grant, {DW-2{1'b0}}};

endmodule