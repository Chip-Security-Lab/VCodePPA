//SystemVerilog
module registered_mux_8to1(
    input [3:0] data0, data1, data2, data3,
    input [3:0] data4, data5, data6, data7,
    input [2:0] addr,
    input clk,
    input req,
    output reg ack,
    output reg [3:0] q_out
);
    reg [3:0] selected_data;
    reg req_d;
    
    // Buffer for high fanout signal
    reg [3:0] selected_data_buf;

    always @(*) begin
        case (addr)
            3'd0: selected_data = data0;
            3'd1: selected_data = data1;
            3'd2: selected_data = data2;
            3'd3: selected_data = data3;
            3'd4: selected_data = data4;
            3'd5: selected_data = data5;
            3'd6: selected_data = data6;
            3'd7: selected_data = data7;
        endcase
    end

    // Buffering the selected_data to reduce fanout
    always @(posedge clk) begin
        selected_data_buf <= selected_data; // Add buffer
        req_d <= req;
        if (req_d) begin
            q_out <= selected_data_buf; // Use buffered data
            ack <= 1'b1;
        end else begin
            ack <= 1'b0;
        end
    end
endmodule