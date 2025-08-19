module cam_2 (
    input wire clk,
    input wire rst,         
    // Write interface with valid-ready handshake
    input wire write_valid,    
    output reg write_ready,
    input wire [1:0] write_addr, 
    input wire [7:0] in_data,
    // Read interface with valid-ready handshake
    input wire read_valid,
    output reg read_ready,
    output reg [3:0] cam_address,
    output reg cam_valid
);
    reg [7:0] data0, data1, data2, data3;
    reg write_done, read_done;
    
    // Write ready generation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            write_ready <= 1'b1; // Initially ready to accept write
            write_done <= 1'b0;
        end else begin
            if (write_valid && write_ready) begin
                write_ready <= 1'b0; // Deassert ready after accepting write
                write_done <= 1'b1;
            end else begin
                write_ready <= 1'b1; // Ready for next transaction
                write_done <= 1'b0;
            end
        end
    end
    
    // Read ready generation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            read_ready <= 1'b1; // Initially ready to accept read
            read_done <= 1'b0;
        end else begin
            if (read_valid && read_ready) begin
                read_ready <= 1'b0; // Deassert ready after accepting read
                read_done <= 1'b1;
            end else begin
                read_ready <= 1'b1; // Ready for next transaction
                read_done <= 1'b0;
            end
        end
    end
    
    // CAM core logic
    always @(posedge clk) begin
        if (rst) begin
            data0 <= 8'b0;
            data1 <= 8'b0;
            data2 <= 8'b0;
            data3 <= 8'b0;
            cam_address <= 4'h0;
            cam_valid <= 1'b0;
        end 
        else begin
            // Default value for cam_valid
            cam_valid <= 1'b0;
            
            // Write operation with valid-ready handshake
            if (write_valid && write_ready) begin
                case (write_addr)
                    2'b00: data0 <= in_data;
                    2'b01: data1 <= in_data;
                    2'b10: data2 <= in_data;
                    2'b11: data3 <= in_data;
                endcase
            end 
            
            // Read operation with valid-ready handshake
            if (read_valid && read_ready) begin
                if (data0 == in_data) begin
                    cam_address <= 4'h0;
                    cam_valid <= 1'b1;
                end 
                else if (data1 == in_data) begin
                    cam_address <= 4'h1;
                    cam_valid <= 1'b1;
                end 
                else if (data2 == in_data) begin
                    cam_address <= 4'h2;
                    cam_valid <= 1'b1;
                end 
                else if (data3 == in_data) begin
                    cam_address <= 4'h3;
                    cam_valid <= 1'b1;
                end 
                else begin
                    cam_valid <= 1'b0;
                    cam_address <= 4'h0;
                end
            end
        end
    end
endmodule