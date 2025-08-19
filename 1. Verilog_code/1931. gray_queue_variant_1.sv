//SystemVerilog
// Top-level module: gray_queue
module gray_queue #(parameter DW=8) (
    input clk,
    input rst,
    input en,
    input [DW-1:0] din,
    output [DW-1:0] dout,
    output error
);

    // Internal signals for inter-module connection
    wire [DW:0] gray_in;
    wire [DW:0] queue_out;

    // Parity and input packing module
    gray_input_packer #(.DW(DW)) u_gray_input_packer (
        .clk(clk),
        .rst(rst),
        .en(en),
        .din(din),
        .gray_packed(gray_in)
    );

    // 2-entry FIFO queue module
    gray_queue_fifo #(.DW(DW)) u_gray_queue_fifo (
        .clk(clk),
        .rst(rst),
        .en(en),
        .data_in(gray_in),
        .data_out(queue_out)
    );

    // Output and error logic module
    gray_queue_out #(.DW(DW)) u_gray_queue_out (
        .clk(clk),
        .rst(rst),
        .en(en),
        .queue_entry(queue_out),
        .dout(dout),
        .error(error)
    );

endmodule

// ---------------------------------------------------------------------------
// gray_input_packer
// Packs input data and its parity into a single vector and registers it
// ---------------------------------------------------------------------------
module gray_input_packer #(parameter DW=8) (
    input clk,
    input rst,
    input en,
    input [DW-1:0] din,
    output reg [DW:0] gray_packed
);
    wire parity;
    assign parity = ^din;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            gray_packed <= { (DW+1){1'b0} };
        end else if (en) begin
            gray_packed <= {din, parity};
        end
    end
endmodule

// ---------------------------------------------------------------------------
// gray_queue_fifo
// 2-entry FIFO queue for gray-coded input data
// ---------------------------------------------------------------------------
module gray_queue_fifo #(parameter DW=8) (
    input clk,
    input rst,
    input en,
    input [DW:0] data_in,
    output reg [DW:0] data_out
);
    reg [DW:0] queue [0:1];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            queue[0] <= { (DW+1){1'b0} };
            queue[1] <= { (DW+1){1'b0} };
        end else if (en) begin
            queue[0] <= data_in;
            queue[1] <= queue[0];
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_out <= { (DW+1){1'b0} };
        end else if (en) begin
            data_out <= queue[1];
        end
    end
endmodule

// ---------------------------------------------------------------------------
// gray_queue_out
// Extracts output data and calculates error flag from queued entry
// ---------------------------------------------------------------------------
module gray_queue_out #(parameter DW=8) (
    input clk,
    input rst,
    input en,
    input [DW:0] queue_entry,
    output reg [DW-1:0] dout,
    output reg error
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout <= {DW{1'b0}};
        end else if (en) begin
            dout <= queue_entry[DW:1];
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            error <= 1'b0;
        end else if (en) begin
            error <= (^queue_entry[DW:1]) ^ queue_entry[0];
        end
    end
endmodule