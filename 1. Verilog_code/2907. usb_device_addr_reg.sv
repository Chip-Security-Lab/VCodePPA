module usb_device_addr_reg(
    input wire clk,
    input wire rst_b,
    input wire set_address,
    input wire [6:0] new_address,
    input wire [3:0] pid,
    input wire [6:0] token_address,
    output reg address_match,
    output reg [6:0] device_address
);
    localparam PID_SETUP = 4'b1101;
    localparam PID_IN = 4'b1001;
    localparam PID_OUT = 4'b0001;
    
    // Device address register
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            device_address <= 7'h00;
        end else if (set_address) begin
            device_address <= new_address;
        end
    end
    
    // Address matching logic
    always @(*) begin
        if (pid == PID_SETUP) begin
            // Always accept SETUP transactions addressed to endpoint 0
            address_match = (token_address == device_address || token_address == 7'h00);
        end else if (pid == PID_IN || pid == PID_OUT) begin
            // Accept IN/OUT only if addressed to us
            address_match = (token_address == device_address);
        end else begin
            address_match = 1'b0;
        end
    end
endmodule