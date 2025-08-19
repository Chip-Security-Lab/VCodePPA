//SystemVerilog
module registered_mux_8to1_valid_ready(
    input [3:0] data0, data1, data2, data3,
    input [3:0] data4, data5, data6, data7,
    input [2:0] addr,
    input clk,
    input rst_n,
    input valid,
    output reg ready,
    output reg [3:0] q_out
);

    reg [3:0] data_reg;
    reg addr_valid_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready <= 1'b0;
            data_reg <= 4'b0;
            addr_valid_reg <= 1'b0;
            q_out <= 4'b0;
        end
        else begin
            ready <= !addr_valid_reg;
            
            if (valid && ready) begin
                case (addr)
                    3'd0: data_reg <= data0;
                    3'd1: data_reg <= data1;
                    3'd2: data_reg <= data2;
                    3'd3: data_reg <= data3;
                    3'd4: data_reg <= data4;
                    3'd5: data_reg <= data5;
                    3'd6: data_reg <= data6;
                    3'd7: data_reg <= data7;
                endcase
                addr_valid_reg <= 1'b1;
            end
            else if (addr_valid_reg) begin
                addr_valid_reg <= 1'b0;
            end
            
            if (addr_valid_reg) begin
                q_out <= data_reg;
            end
        end
    end

endmodule