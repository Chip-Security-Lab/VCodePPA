module registered_mux_8to1(
    input [3:0] data0, data1, data2, data3,
    input [3:0] data4, data5, data6, data7,
    input [2:0] addr,
    input clk,
    output reg [3:0] q_out
);
    reg [3:0] selected_data;
    
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
    
    always @(posedge clk)
        q_out <= selected_data;
endmodule