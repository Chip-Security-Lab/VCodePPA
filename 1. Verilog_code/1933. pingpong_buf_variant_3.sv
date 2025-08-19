//SystemVerilog
module pingpong_buf_pipeline #(parameter DW=16) (
    input                  clk,
    input                  rst_n,
    input                  switch,
    input  [DW-1:0]        din,
    input                  din_valid,
    output [DW-1:0]        dout,
    output                 dout_valid
);

    // Stage 1: Input latch and control logic
    reg [DW-1:0]           din_stage1;
    reg                    switch_stage1;
    reg                    din_valid_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            din_stage1        <= {DW{1'b0}};
            switch_stage1     <= 1'b0;
            din_valid_stage1  <= 1'b0;
        end else begin
            din_stage1        <= din;
            switch_stage1     <= switch;
            din_valid_stage1  <= din_valid;
        end
    end

    // Stage 2: Optimized ping-pong buffer write/read logic
    reg [DW-1:0]           buf_ping;
    reg [DW-1:0]           buf_pong;
    reg                    buffer_select;
    reg [DW-1:0]           data_out_stage2;
    reg                    data_out_valid_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buf_ping                <= {DW{1'b0}};
            buf_pong                <= {DW{1'b0}};
            buffer_select           <= 1'b0;
            data_out_stage2         <= {DW{1'b0}};
            data_out_valid_stage2   <= 1'b0;
        end else begin
            // Default outputs
            data_out_valid_stage2 <= 1'b0;
            // Only update on valid input
            if (din_valid_stage1) begin
                if (switch_stage1) begin
                    // Output data from the currently selected buffer, toggle select
                    data_out_stage2       <= buffer_select ? buf_ping : buf_pong;
                    data_out_valid_stage2 <= 1'b1;
                    buffer_select         <= ~buffer_select;
                end else begin
                    // Write new data to the inactive buffer
                    if (buffer_select)
                        buf_pong <= din_stage1;
                    else
                        buf_ping <= din_stage1;
                end
            end
        end
    end

    // Stage 3: Output register
    reg [DW-1:0]           data_out_stage3;
    reg                    data_out_valid_stage3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out_stage3        <= {DW{1'b0}};
            data_out_valid_stage3  <= 1'b0;
        end else begin
            data_out_stage3        <= data_out_stage2;
            data_out_valid_stage3  <= data_out_valid_stage2;
        end
    end

    assign dout       = data_out_stage3;
    assign dout_valid = data_out_valid_stage3;

endmodule