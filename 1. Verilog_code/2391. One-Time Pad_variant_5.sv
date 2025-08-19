//SystemVerilog

// Top-level module
module one_time_pad #(parameter WIDTH = 24) (
    input wire clk, reset_n,
    input wire activate, new_key,
    input wire [WIDTH-1:0] data_input, key_input,
    output wire [WIDTH-1:0] data_output,
    output wire ready
);
    // Internal signals
    wire [WIDTH-1:0] current_key;
    wire key_ready;
    wire encrypt_done;
    
    // Key management submodule
    key_manager #(.WIDTH(WIDTH)) key_mgr (
        .clk(clk),
        .reset_n(reset_n),
        .new_key(new_key),
        .key_input(key_input),
        .current_key(current_key),
        .key_ready(key_ready)
    );
    
    // Encryption submodule
    encryptor #(.WIDTH(WIDTH)) enc_unit (
        .clk(clk),
        .reset_n(reset_n),
        .activate(activate),
        .key_ready(key_ready),
        .data_input(data_input),
        .current_key(current_key),
        .data_output(data_output),
        .ready(ready),
        .encrypt_done(encrypt_done)
    );
    
endmodule

// Key management module
module key_manager #(parameter WIDTH = 24) (
    input wire clk, reset_n,
    input wire new_key,
    input wire [WIDTH-1:0] key_input,
    output reg [WIDTH-1:0] current_key,
    output reg key_ready
);
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            current_key <= {WIDTH{1'b0}};
            key_ready <= 1'b0;
        end else if (new_key) begin
            current_key <= key_input;
            key_ready <= 1'b1;
        end
    end
endmodule

// Encryption module
module encryptor #(parameter WIDTH = 24) (
    input wire clk, reset_n,
    input wire activate,
    input wire key_ready,
    input wire [WIDTH-1:0] data_input, current_key,
    output reg [WIDTH-1:0] data_output,
    output reg ready,
    output reg encrypt_done
);
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            data_output <= {WIDTH{1'b0}};
            ready <= 1'b0;
            encrypt_done <= 1'b0;
        end else if (activate && key_ready) begin
            data_output <= data_input ^ current_key;
            ready <= 1'b0;  // One-time use
            encrypt_done <= 1'b1;
        end else if (!activate) begin
            encrypt_done <= 1'b0;
            ready <= key_ready;
        end
    end
endmodule