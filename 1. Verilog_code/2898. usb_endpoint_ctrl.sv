module usb_endpoint_ctrl #(
    parameter NUM_ENDPOINTS = 4
)(
    input wire clk,
    input wire rst,
    input wire [3:0] ep_num,
    input wire ep_select,
    input wire ep_stall_set,
    input wire ep_stall_clr,
    output reg [NUM_ENDPOINTS-1:0] ep_stall_status,
    output reg valid_ep
);
    integer i;
    
    always @(posedge clk) begin
        if (rst) begin
            ep_stall_status <= {NUM_ENDPOINTS{1'b0}};
            valid_ep <= 1'b0;
        end else if (ep_select) begin
            valid_ep <= (ep_num < NUM_ENDPOINTS);
            if (ep_num < NUM_ENDPOINTS) begin
                if (ep_stall_set)
                    ep_stall_status[ep_num] <= 1'b1;
                else if (ep_stall_clr)
                    ep_stall_status[ep_num] <= 1'b0;
            end
        end else begin
            valid_ep <= 1'b0;
        end
    end
endmodule