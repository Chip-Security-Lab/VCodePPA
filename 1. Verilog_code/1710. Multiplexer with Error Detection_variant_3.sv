//SystemVerilog
module error_detect_mux(
    input clk,
    input rst_n,
    input [7:0] in_a, in_b, in_c, in_d,
    input [1:0] select,
    input req_a, req_b, req_c, req_d,
    output reg [7:0] out_data,
    output reg error_flag,
    output reg ack_a, ack_b, ack_c, ack_d
);

    // Pipeline stage 1: Input selection and validation
    reg [7:0] selected_data;
    reg selected_req;
    reg [1:0] selected_channel;
    
    always @(*) begin
        case (select)
            2'b00: begin
                selected_data = in_a;
                selected_req = req_a;
                selected_channel = 2'b00;
            end
            2'b01: begin
                selected_data = in_b;
                selected_req = req_b;
                selected_channel = 2'b01;
            end
            2'b10: begin
                selected_data = in_c;
                selected_req = req_c;
                selected_channel = 2'b10;
            end
            2'b11: begin
                selected_data = in_d;
                selected_req = req_d;
                selected_channel = 2'b11;
            end
        endcase
    end

    // Pipeline stage 2: Error detection and output registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_data <= 8'b0;
            error_flag <= 1'b0;
            ack_a <= 1'b0;
            ack_b <= 1'b0;
            ack_c <= 1'b0;
            ack_d <= 1'b0;
        end else begin
            out_data <= selected_data;
            error_flag <= !selected_req;
            
            // Generate ack signals based on selected channel
            ack_a <= (selected_channel == 2'b00) && selected_req;
            ack_b <= (selected_channel == 2'b01) && selected_req;
            ack_c <= (selected_channel == 2'b10) && selected_req;
            ack_d <= (selected_channel == 2'b11) && selected_req;
        end
    end

endmodule