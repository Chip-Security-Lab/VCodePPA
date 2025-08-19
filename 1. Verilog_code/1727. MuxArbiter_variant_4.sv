//SystemVerilog
module MuxArbiter #(parameter W=8) (
    input clk,
    input [3:0] req,
    input [3:0][W-1:0] data,
    output reg [W-1:0] grant_data,
    output reg [3:0] grant
);

    wire [1:0] selected;
    wire [W-1:0] selected_data;

    PriorityEncoder #(W) encoder (
        .clk(clk),
        .req(req),
        .selected(selected)
    );

    DataSelector #(W) selector (
        .data(data),
        .selected(selected),
        .selected_data(selected_data)
    );

    always @(posedge clk) begin
        grant <= 1 << selected;
        grant_data <= selected_data;
    end
endmodule

module PriorityEncoder #(parameter W=8) (
    input clk,
    input [3:0] req,
    output reg [1:0] selected
);

    wire [3:0] borrow;
    wire [3:0] diff;
    
    // Borrow subtractor implementation
    assign borrow[0] = 1'b0;
    assign diff[0] = req[0] ^ borrow[0];
    assign borrow[1] = ~req[0] & borrow[0];
    
    assign diff[1] = req[1] ^ borrow[1];
    assign borrow[2] = ~req[1] & borrow[1];
    
    assign diff[2] = req[2] ^ borrow[2];
    assign borrow[3] = ~req[2] & borrow[2];
    
    assign diff[3] = req[3] ^ borrow[3];

    always @(posedge clk) begin
        if (diff[0]) selected <= 2'b00;
        else if (diff[1]) selected <= 2'b01;
        else if (diff[2]) selected <= 2'b10;
        else if (diff[3]) selected <= 2'b11;
        else selected <= 2'bxx;
    end
endmodule

module DataSelector #(parameter W=8) (
    input [3:0][W-1:0] data,
    input [1:0] selected,
    output reg [W-1:0] selected_data
);
    always @(*) begin
        case (selected)
            2'b00: selected_data = data[0];
            2'b01: selected_data = data[1];
            2'b10: selected_data = data[2];
            2'b11: selected_data = data[3];
            default: selected_data = {W{1'b0}};
        endcase
    end
endmodule