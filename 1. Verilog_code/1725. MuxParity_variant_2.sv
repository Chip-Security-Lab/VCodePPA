//SystemVerilog
module MuxParity #(parameter W=8) (
    input [3:0][W:0] data_ch, // [W] is parity
    input [1:0] sel,
    output reg [W:0] data_out
);

    wire [W-1:0] selected_data;
    wire [3:0] parity_result;

    // Data selection submodule
    DataSelector #(.W(W)) data_selector (
        .data_ch(data_ch),
        .sel(sel),
        .selected_data(selected_data)
    );

    // Parity calculation submodule
    ParityCalculator #(.W(W)) parity_calc (
        .data_in(selected_data),
        .parity_out(parity_result)
    );

    // Output generation logic
    always @(*) begin
        data_out = {parity_result[0], selected_data};
    end

endmodule

// Data selection submodule
module DataSelector #(parameter W=8) (
    input [3:0][W:0] data_ch,
    input [1:0] sel,
    output reg [W-1:0] selected_data
);

    always @(*) begin
        case(sel)
            2'b00: selected_data = data_ch[0][W-1:0];
            2'b01: selected_data = data_ch[1][W-1:0];
            2'b10: selected_data = data_ch[2][W-1:0];
            2'b11: selected_data = data_ch[3][W-1:0];
        endcase
    end

endmodule

// Parity calculation submodule
module ParityCalculator #(parameter W=8) (
    input [W-1:0] data_in,
    output reg [3:0] parity_out
);

    always @(*) begin
        parity_out = data_in[0] + data_in[1] + data_in[2] + data_in[3] +
                    data_in[4] + data_in[5] + data_in[6] + data_in[7];
    end

endmodule