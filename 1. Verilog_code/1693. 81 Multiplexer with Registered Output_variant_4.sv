//SystemVerilog
module registered_mux_8to1(
    input [3:0] data0, data1, data2, data3,
    input [3:0] data4, data5, data6, data7,
    input [2:0] addr,
    input clk,
    input valid,
    output reg ready,
    output reg [3:0] q_out
);
    reg [3:0] selected_data;
    reg [3:0] pipeline_reg;
    reg valid_reg;
    
    // First stage: Address decoding and data selection
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
    
    // Pipeline stage with valid-ready handshake
    always @(posedge clk) begin
        if (ready) begin
            pipeline_reg <= selected_data;
            valid_reg <= valid;
        end
    end
    
    // Ready signal generation
    always @(*) begin
        ready = ~valid_reg;
    end
    
    // Final output stage
    always @(posedge clk) begin
        if (valid_reg) begin
            q_out <= pipeline_reg;
        end
    end
endmodule