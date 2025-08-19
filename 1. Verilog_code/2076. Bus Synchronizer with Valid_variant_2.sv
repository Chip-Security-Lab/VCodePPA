//SystemVerilog
module bus_sync_valid #(parameter BUS_WIDTH = 16) (
    input wire src_clk,
    input wire dst_clk,
    input wire rst,
    input wire [BUS_WIDTH-1:0] data_in,
    input wire valid_in,
    output reg valid_out,
    output reg [BUS_WIDTH-1:0] data_out
);
    reg valid_toggle;
    reg [BUS_WIDTH-1:0] data_capture;
    reg [2:0] sync_valid;

    wire [2:0] valid_toggle_vec;
    assign valid_toggle_vec = {sync_valid[1:0], valid_toggle};

    wire [2:0] sub_a, sub_b;
    wire [2:0] diff;
    wire borrow_out;

    assign sub_a = valid_toggle_vec[2:0];
    assign sub_b = {sync_valid[2], sync_valid[1], 1'b0};

    // Unrolled 3-bit borrow subtractor
    wire [2:0] minuend;
    wire [2:0] subtrahend;
    wire [2:0] difference;
    wire [2:0] borrow;

    assign minuend = sub_a;
    assign subtrahend = sub_b;

    assign borrow[0] = subtrahend[0] > minuend[0];
    assign difference[0] = minuend[0] ^ subtrahend[0];

    assign borrow[1] = (subtrahend[1] + borrow[0]) > minuend[1];
    assign difference[1] = minuend[1] ^ subtrahend[1] ^ borrow[0];

    assign borrow[2] = (subtrahend[2] + borrow[1]) > minuend[2];
    assign difference[2] = minuend[2] ^ subtrahend[2] ^ borrow[1];

    assign borrow_out = borrow[2];
    assign diff = difference;

    // Source domain logic
    always @(posedge src_clk) begin
        if (rst) begin
            valid_toggle <= 1'b0;
            data_capture <= {BUS_WIDTH{1'b0}};
        end else if (valid_in) begin
            valid_toggle <= ~valid_toggle;
            data_capture <= data_in;
        end
    end

    // Destination domain logic
    always @(posedge dst_clk) begin
        if (rst) begin
            sync_valid <= 3'b0;
            valid_out <= 1'b0;
            data_out <= {BUS_WIDTH{1'b0}};
        end else begin
            sync_valid <= {sync_valid[1:0], valid_toggle};
            valid_out <= diff[0];
            if (diff[0]) data_out <= data_capture;
        end
    end

endmodule