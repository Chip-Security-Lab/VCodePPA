module usb_speed_detector(
    input wire clk,
    input wire rst_n,
    input wire dp,
    input wire dm,
    input wire detect_en,
    output reg low_speed,
    output reg full_speed,
    output reg no_device,
    output reg chirp_detected,
    output reg [1:0] detection_state
);
    localparam IDLE = 2'b00;
    localparam WAIT_STABLE = 2'b01;
    localparam DETECT = 2'b10;
    localparam COMPLETE = 2'b11;
    
    reg [9:0] stability_counter;
    reg prev_dp, prev_dm;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            detection_state <= IDLE;
            low_speed <= 1'b0;
            full_speed <= 1'b0;
            no_device <= 1'b1;
            chirp_detected <= 1'b0;
            stability_counter <= 10'd0;
            prev_dp <= 1'b0;
            prev_dm <= 1'b0;
        end else begin
            prev_dp <= dp;
            prev_dm <= dm;
            
            case (detection_state)
                IDLE: begin
                    if (detect_en) begin
                        detection_state <= WAIT_STABLE;
                        stability_counter <= 10'd0;
                    end
                end
                WAIT_STABLE: begin
                    if (dp == prev_dp && dm == prev_dm) begin
                        if (stability_counter >= 10'd500) // ~10µs at 48MHz
                            detection_state <= DETECT;
                        else
                            stability_counter <= stability_counter + 10'd1;
                    end else begin
                        stability_counter <= 10'd0;
                    end
                end
                DETECT: begin
                    no_device <= !(dp || dm);
                    full_speed <= dp && !dm;
                    low_speed <= !dp && dm;
                    chirp_detected <= dp && dm;
                    detection_state <= COMPLETE;
                end
                COMPLETE: begin
                    if (!detect_en)
                        detection_state <= IDLE;
                end
            endcase
        end
    end
endmodule