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
    reg req_reg;
    wire [3:0] baugh_wooley_result;
    
    // Baugh-Wooley multiplier implementation
    assign baugh_wooley_result[0] = selected_data[0] & selected_data[0];
    assign baugh_wooley_result[1] = (selected_data[1] & selected_data[0]) ^ 
                                   (selected_data[0] & selected_data[1]);
    assign baugh_wooley_result[2] = (selected_data[2] & selected_data[0]) ^ 
                                   (selected_data[1] & selected_data[1]) ^ 
                                   (selected_data[0] & selected_data[2]);
    assign baugh_wooley_result[3] = (selected_data[3] & selected_data[0]) ^ 
                                   (selected_data[2] & selected_data[1]) ^ 
                                   (selected_data[1] & selected_data[2]) ^ 
                                   (selected_data[0] & selected_data[3]);
    
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
    
    always @(posedge clk) begin
        req_reg <= req;
        if (req_reg) begin
            q_out <= baugh_wooley_result;
            ack <= 1'b1;
        end else begin
            ack <= 1'b0;
        end
    end
endmodule